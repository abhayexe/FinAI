import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';

class RecurringExpenseEditDialog extends StatelessWidget {
  final Transaction expense;
  final Function(Transaction) onDelete;

  const RecurringExpenseEditDialog({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Recurring Expense',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this recurring expense?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              onDelete(expense);
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close details dialog
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyData = Provider.of<CurrencyProvider>(context, listen: false);
    final frequency = expense.recurringFrequency?.replaceFirst(
      expense.recurringFrequency![0],
      expense.recurringFrequency![0].toUpperCase(),
    );
    final day = expense.recurringDay != null ? ' (Day ${expense.recurringDay})' : '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurring Expense Details',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _detailRow(
              'Title',
              expense.title,
              Icons.title,
            ),
            const SizedBox(height: 16),
            _detailRow(
              'Amount',
              currencyData.formatAmount(expense.amount),
              Icons.attach_money,
            ),
            const SizedBox(height: 16),
            _detailRow(
              'Frequency',
              '$frequency$day',
              Icons.calendar_today,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    'Delete',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
