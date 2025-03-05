import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import '../models/transaction.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  void _showTransactionDetails(BuildContext context, Transaction transaction, FinanceProvider financeData, CurrencyProvider currencyData) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: _getCategoryColor(transaction.category),
                    child: Icon(
                      _getCategoryIcon(transaction.category),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          transaction.category,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(
                'Amount',
                Text(
                  financeData.formatAmount(transaction.amount, currencyData),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: transaction.amount < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _detailRow(
                'Date',
                Text(
                  DateFormat('MMMM dd, yyyy').format(transaction.date),
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              _detailRow(
                'Time',
                Text(
                  DateFormat('hh:mm a').format(transaction.date),
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showDeleteConfirmation(context, transaction, financeData, currencyData);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        value,
      ],
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Transaction transaction, FinanceProvider financeData, CurrencyProvider currencyData) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Transaction',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 16,
            ),
            children: [
              const TextSpan(text: 'Are you sure you want to delete the transaction:\n\n'),
              TextSpan(
                text: transaction.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: ' ('),
              TextSpan(
                text: financeData.formatAmount(transaction.amount, currencyData),
                style: TextStyle(
                  color: transaction.amount < 0 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ')?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              financeData.deleteTransaction(transaction.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Transactions',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer2<FinanceProvider, CurrencyProvider>(
        builder: (context, financeData, currencyData, _) {
          final transactions = financeData.transactions.where((tx) => !tx.isRecurring).toList();

          if (transactions.isEmpty) {
            return Center(
              child: Text(
                'No transactions yet',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (ctx, index) {
              final transaction = transactions[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(transaction.category),
                    child: Icon(
                      _getCategoryIcon(transaction.category),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    transaction.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(transaction.date),
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: Text(
                    financeData.formatAmount(transaction.amount, currencyData),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: transaction.amount < 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  onTap: () => _showTransactionDetails(
                    context,
                    transaction,
                    financeData,
                    currencyData,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transportation':
        return Colors.blue;
      case 'utilities':
        return Colors.purple;
      case 'entertainment':
        return Colors.pink;
      case 'shopping':
        return Colors.teal;
      case 'health':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transportation':
        return Icons.directions_car;
      case 'utilities':
        return Icons.home;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.attach_money;
    }
  }
}
