import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bank_account.dart';
import '../models/bank_transfer.dart';
import '../providers/bank_account_provider.dart';

class TransferScreen extends StatefulWidget {
  static const routeName = '/transfer';

  const TransferScreen({Key? key}) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _fromAccountId;
  String? _toAccountId;
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<BankAccountProvider>(context, listen: false)
          .loadAccounts()
          .then((_) {
        final provider =
            Provider.of<BankAccountProvider>(context, listen: false);
        if (provider.accounts.length > 1) {
          // Set default from account to the currently selected account or the first account
          setState(() {
            _fromAccountId =
                provider.selectedAccount?.id ?? provider.accounts.first.id;

            // Set default to account as the first account that is not the from account
            _toAccountId = provider.accounts
                .firstWhere((account) => account.id != _fromAccountId)
                .id;
          });
        }

        setState(() {
          _isLoading = false;
        });
      }).catchError((error) {
        // Show a more helpful error message if the table doesn't exist
        String errorMessage = 'Failed to load accounts: ${error.toString()}';
        if (error.toString().contains('404')) {
          errorMessage =
              'The bank_accounts table needs to be set up in Supabase. Please visit the Accounts screen for setup instructions.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      });

      _isInit = true;
    }
    super.didChangeDependencies();
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate() ||
        _fromAccountId == null ||
        _toAccountId == null) {
      return;
    }

    // Make sure from and to accounts are different
    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You cannot transfer money to the same account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<BankAccountProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      final transfer = await provider.createTransfer(
        sourceAccountId: _fromAccountId!,
        destinationAccountId: _toAccountId!,
        amount: amount,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transfer completed successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _amountController.clear();
      _descriptionController.clear();

      // Navigate back to accounts screen
      Navigator.of(context).pop();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete transfer: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAccountLabel(BankAccount account) {
    return '${account.name} (${account.bankName}) - \$${account.balance.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<BankAccountProvider>(context);
    final accounts = accountProvider.accounts;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Transfer Money'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (accounts.length < 2) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Transfer Money'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'You need at least two accounts to make a transfer',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Back to Accounts'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Money'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _fromAccountId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: accounts.map((account) {
                          return DropdownMenuItem<String>(
                            value: account.id,
                            child: Text(_getAccountLabel(account)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _fromAccountId = value;

                            // If to and from are the same, change the to account
                            if (_toAccountId == value) {
                              _toAccountId = accounts
                                  .firstWhere((account) => account.id != value)
                                  .id;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a source account';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _toAccountId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: accounts
                            .where((account) => account.id != _fromAccountId)
                            .map((account) {
                          return DropdownMenuItem<String>(
                            value: account.id,
                            child: Text(_getAccountLabel(account)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _toAccountId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a destination account';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter amount to transfer',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Please enter a valid number';
                          }
                          if (amount <= 0) {
                            return 'Amount must be greater than zero';
                          }

                          // Check if there are sufficient funds
                          if (_fromAccountId != null) {
                            final fromAccount = accounts.firstWhere(
                              (account) => account.id == _fromAccountId,
                            );
                            if (amount > fromAccount.balance) {
                              return 'Insufficient funds in the source account';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Enter a description for this transfer',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTransfer,
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'Complete Transfer',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
