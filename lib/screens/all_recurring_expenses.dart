import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/recurring_expense_edit_dialog.dart';

class AllRecurringExpensesScreen extends StatelessWidget {
  const AllRecurringExpensesScreen({super.key});

  String _normalizeFrequencyDisplay(String? freq) {
    if (freq == null) return 'Every month';
    switch (freq.toLowerCase()) {
      case 'daily':
      case 'day':
        return 'Every day';
      case 'weekly':
      case 'week':
        return 'Every week';
      case 'monthly':
      case 'month':
        return 'Every month';
      case 'yearly':
      case 'year':
        return 'Every year';
      default:
        return 'Every ${freq.toLowerCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Recurring Expenses',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer2<FinanceProvider, CurrencyProvider>(
        builder: (context, financeData, currencyData, _) {
          final recurringExpenses = financeData.getRecurringTransactions();

          if (recurringExpenses.isEmpty) {
            return Center(
              child: Text(
                'No recurring expenses yet',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recurringExpenses.length,
            itemBuilder: (ctx, index) {
              final expense = recurringExpenses[index];
              final frequency = _normalizeFrequencyDisplay(expense.recurringFrequency);
              final day = expense.recurringDay != null ? 
                        ' (Day ${expense.recurringDay})' : '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.repeat, color: Colors.white),
                  ),
                  title: Text(
                    expense.title.replaceAll(' (Recurring)', ''),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '$frequency$day',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Text(
                    financeData.formatAmount(expense.amount, currencyData),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => RecurringExpenseEditDialog(
                        expense: expense,
                        onDelete: (expense) {
                          Provider.of<FinanceProvider>(context, listen: false)
                              .deleteRecurringExpense(expense);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
