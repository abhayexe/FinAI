import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/bank_account.dart';
import '../providers/bank_account_provider.dart';

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({Key? key}) : super(key: key);

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _balanceController = TextEditingController();

  BankAccountType _selectedType = BankAccountType.checking;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final accountProvider =
          Provider.of<BankAccountProvider>(context, listen: false);

      await accountProvider.addAccount(
        name: _nameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        type: _selectedType,
        initialBalance: double.parse(_balanceController.text),
        bankName: _bankNameController.text.trim(),
        isDefault: _isDefault,
      );

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account added successfully')),
      );
    } catch (e) {
      String errorMessage = 'Failed to add account: ${e.toString()}';

      // Provide a more helpful error message for common issues
      if (e.toString().contains('404')) {
        errorMessage =
            'The bank_accounts table needs to be set up in Supabase. Please check the accounts screen for setup instructions.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'E.g., Personal Checking',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Account number
              TextFormField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Enter account number',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Bank name
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'E.g., Chase, Bank of America',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a bank name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Initial balance
              TextFormField(
                controller: _balanceController,
                decoration: InputDecoration(
                  labelText: 'Initial Balance',
                  hintText: 'Enter initial balance',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an initial balance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Account type selection
              DropdownButtonFormField<BankAccountType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: BankAccountType.values.map((type) {
                  return DropdownMenuItem<BankAccountType>(
                    value: type,
                    child: Text(type.toDisplayString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),

              // Default account checkbox
              CheckboxListTile(
                title: Text('Set as default account'),
                value: _isDefault,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveAccount,
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text('Add Account'),
        ),
      ],
    );
  }
}