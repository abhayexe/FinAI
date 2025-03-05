import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';

class RecurringExpenseDialog extends StatefulWidget {
  final Transaction? existingTransaction;

  const RecurringExpenseDialog({
    super.key,
    this.existingTransaction,
  });

  @override
  _RecurringExpenseDialogState createState() => _RecurringExpenseDialogState();
}

class _RecurringExpenseDialogState extends State<RecurringExpenseDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Rent';
  int _selectedDay = 1;
  String _selectedFrequency = 'Monthly';

  final List<String> _categories = [
    'Rent',
    'Utilities',
    'Internet',
    'Phone',
    'Insurance',
    'Groceries',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Other'
  ];

  final List<String> _frequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly'
  ];

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Recurring Expense'),
          content: const Text('Are you sure you want to delete this recurring expense?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _titleController.text = widget.existingTransaction!.title.replaceAll(' (Recurring)', '');
      _amountController.text = widget.existingTransaction!.amount.toString();
      _selectedCategory = widget.existingTransaction!.category;
      _selectedDay = widget.existingTransaction!.recurringDay ?? 1;
      _selectedFrequency = widget.existingTransaction!.recurringFrequency ?? 'Monthly';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

    final transaction = Transaction(
      id: widget.existingTransaction?.id ?? DateTime.now().toString(),
      title: '${_titleController.text} (Recurring)',
      amount: amount,
      category: _selectedCategory,
      date: widget.existingTransaction?.date ?? DateTime.now(),
      isRecurring: true,
      recurringDay: _selectedDay,
      recurringFrequency: _selectedFrequency,
    );

    if (widget.existingTransaction != null) {
      financeProvider.updateTransaction(transaction);
    } else {
      financeProvider.addTransaction(transaction);
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existingTransaction != null 
                  ? 'Edit Recurring Expense'
                  : 'Add Recurring Expense',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _frequencies.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(frequency),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFrequency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedDay,
              decoration: InputDecoration(
                labelText: 'Day of Month',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: List.generate(31, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text('${index + 1}'),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDay = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _submitForm(context),
                  child: Text(
                    widget.existingTransaction != null 
                        ? 'Update Expense'
                        : 'Add Expense'
                  ),
                ),
                const SizedBox(width: 8),
                widget.existingTransaction != null
                  ? ElevatedButton(
                      onPressed: () async {
                        final shouldDelete = await _showDeleteConfirmationDialog(context);
                        if (shouldDelete) {
                          final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
                          await financeProvider.deleteRecurringExpense(widget.existingTransaction!);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('Delete'),
                    )
                  : Container(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
