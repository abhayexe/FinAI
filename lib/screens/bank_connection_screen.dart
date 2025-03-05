import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/razorpay_service.dart';

class BankConnectionScreen extends StatefulWidget {
  const BankConnectionScreen({super.key});

  @override
  _BankConnectionScreenState createState() => _BankConnectionScreenState();
}

class _BankConnectionScreenState extends State<BankConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  
  final RazorpayService _razorpayService = RazorpayService();
  
  bool _isLoading = false;
  bool _isBankConnected = false;
  Map<String, dynamic>? _bankDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBankConnection();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    super.dispose();
  }

  Future<void> _checkBankConnection() async {
    setState(() {
      _isLoading = true;
    });
    
    final result = await _razorpayService.getBankAccountDetails();
    
    setState(() {
      _isLoading = false;
      _isBankConnected = result['success'];
      if (_isBankConnected) {
        _bankDetails = result['data'];
      }
    });
  }

  Future<void> _connectBankAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _razorpayService.connectBankAccount(
      accountNumber: _accountNumberController.text,
      ifscCode: _ifscCodeController.text,
      accountHolderName: _accountHolderNameController.text,
    );
    
    setState(() {
      _isLoading = false;
      _isBankConnected = result['success'];
      if (!result['success']) {
        _errorMessage = result['message'];
      } else {
        _bankDetails = result['data'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Connect Bank Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 24,
                            child: Icon(
                              Icons.account_balance,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bank Account Integration',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Powered by RazorpayX',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_isBankConnected && _bankDetails != null)
                      _buildConnectedBankDetails()
                    else
                      _buildBankConnectionForm(),
                      
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConnectedBankDetails() {
    final bankAccount = _bankDetails!['bank_account'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bank Account Connected',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Account Holder', bankAccount['name']),
            _buildDetailRow('Bank', bankAccount['bank_name'] ?? 'Not available'),
            _buildDetailRow('Account Number', '••••${bankAccount['account_number'].toString().substring(bankAccount['account_number'].toString().length - 4)}'),
            _buildDetailRow('IFSC Code', bankAccount['ifsc']),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Account Details'),
                onPressed: _checkBankConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankConnectionForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect Your Bank Account',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountHolderNameController,
                decoration: InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account holder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ifscCodeController,
                decoration: InputDecoration(
                  labelText: 'IFSC Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter IFSC code';
                  }
                  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) {
                    return 'Please enter a valid IFSC code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Connect Bank Account'),
                  onPressed: _connectBankAccount,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Note: Your bank account information is securely processed through RazorpayX and is not stored on our servers.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
