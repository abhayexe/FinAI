import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';
import '../providers/finance_provider.dart';

class LoanDetailsDialog extends StatefulWidget {
  const LoanDetailsDialog({super.key});

  @override
  _LoanDetailsDialogState createState() => _LoanDetailsDialogState();
}

class _LoanDetailsDialogState extends State<LoanDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _durationController = TextEditingController();
  double _interestRate = 5.0; // Default interest rate

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<bool> _showHighInterestWarning(BuildContext context, double monthlyInterest) async {
    final financeData = Provider.of<FinanceProvider>(context, listen: false);
    final currencyData = Provider.of<CurrencyProvider>(context, listen: false);
    
    final currentMonthlyExpenses = financeData.getTotalExpenses();
    final monthlyIncome = financeData.income;
    final newTotalExpenses = currentMonthlyExpenses + monthlyInterest;
    
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Expense Limit Warning',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This loan will cause your expenses to exceed your income:',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _expenseRow(
              'Current Monthly Expenses:',
              currencyData.formatAmount(currentMonthlyExpenses),
              Colors.grey[800]!,
            ),
            _expenseRow(
              'Monthly Interest Payment:',
              '+ ${currencyData.formatAmount(monthlyInterest)}',
              Colors.orange,
            ),
            const Divider(),
            _expenseRow(
              'Total Monthly Expenses:',
              currencyData.formatAmount(newTotalExpenses),
              Colors.red,
            ),
            _expenseRow(
              'Monthly Income:',
              currencyData.formatAmount(monthlyIncome),
              Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              '⚠️ Your monthly expenses will be ${currencyData.formatAmount(newTotalExpenses - monthlyIncome)} more than your income!',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Take Loan Anyway',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _expenseRow(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Details',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Amount',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter loan amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Loan Purpose',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter loan purpose';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (months)',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter loan duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Interest Rate: ${_interestRate.toStringAsFixed(1)}%'),
                    Expanded(
                      child: Slider(
                        value: _interestRate,
                        min: 1.0,
                        max: 20.0,
                        divisions: 38,
                        label: '${_interestRate.toStringAsFixed(1)}%',
                        onChanged: (value) {
                          setState(() {
                            _interestRate = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final loanAmount = double.parse(_amountController.text);
                          final duration = int.parse(_durationController.text);
                          
                          // Calculate monthly interest payment
                          final monthlyInterestRate = _interestRate / 100 / 12;
                          final monthlyInterestPayment = loanAmount * monthlyInterestRate;

                          // Get current expenses and income to check if warning is needed
                          final financeData = Provider.of<FinanceProvider>(context, listen: false);
                          final currentExpenses = financeData.getTotalExpenses();
                          final income = financeData.income;
                          final newTotalExpenses = currentExpenses + monthlyInterestPayment;

                          // Only show warning if new total expenses would exceed income
                          bool shouldProceed = true;
                          if (newTotalExpenses > income) {
                            shouldProceed = await _showHighInterestWarning(
                              context,
                              monthlyInterestPayment,
                            );
                          }

                          if (shouldProceed) {
                            // Create loan transaction (adds to balance)
                            final loanTransaction = Transaction(
                              id: DateTime.now().toString(),
                              title: 'Loan: ${_purposeController.text}',
                              amount: loanAmount,
                              date: DateTime.now(),
                              category: 'Loans',
                              isRecurring: false,
                            );
                            
                            // Create recurring interest expense
                            final interestExpense = Transaction(
                              id: '${DateTime.now().toString()}_interest',
                              title: 'Loan Interest: ${_purposeController.text}',
                              amount: monthlyInterestPayment,
                              date: DateTime.now(),
                              category: 'Interest',
                              isRecurring: true,
                              recurringFrequency: 'monthly',
                              recurringDay: DateTime.now().day,
                            );
                            
                            Navigator.pop(context, {
                              'loanTransaction': loanTransaction,
                              'interestExpense': interestExpense,
                            });
                          }
                        }
                      },
                      child: const Text('Add Loan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
