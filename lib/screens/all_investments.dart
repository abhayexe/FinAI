import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import '../models/investment.dart';
import '../widgets/add_investment.dart';
import '../widgets/investment_return_dialog.dart';

class AllInvestmentsScreen extends StatelessWidget {
  const AllInvestmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Investments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddInvestmentDialog(),
              );
            },
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeData, _) {
          final investments = financeData.investments;
          
          if (investments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No investments yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first investment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: investments.length,
            itemBuilder: (ctx, index) {
              final investment = investments[index];
              return _buildInvestmentItem(context, investment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddInvestmentDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvestmentItem(BuildContext context, Investment investment) {
    final financeData = Provider.of<FinanceProvider>(context, listen: false);
    final currencyData = Provider.of<CurrencyProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showInvestmentDetails(context, investment);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getInvestmentTypeColor(investment.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getInvestmentTypeIcon(investment.type),
                      color: _getInvestmentTypeColor(investment.type),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          investment.type,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        financeData.formatInvestmentAmount(investment, currencyData),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${investment.date.day}/${investment.date.month}/${investment.date.year}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (investment.notes != null && investment.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notes,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          investment.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInvestmentDetails(BuildContext context, Investment investment) {
    final financeData = Provider.of<FinanceProvider>(context, listen: false);
    final currencyData = Provider.of<CurrencyProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Investment Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow(
                'Title',
                Text(
                  investment.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(
                'Amount',
                Text(
                  financeData.formatInvestmentAmount(investment, currencyData),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(
                'Type',
                Text(
                  investment.type,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(
                'Date',
                Text(
                  '${investment.date.day}/${investment.date.month}/${investment.date.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                  ),
                ),
              ),
              if (investment.notes != null && investment.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _detailRow(
                  'Notes',
                  Text(
                    investment.notes!,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showInvestmentReturnDialog(context, investment);
                    },
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('Get Returns'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _editInvestment(context, investment);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _confirmDeleteInvestment(context, investment);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, Widget content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }

  void _showInvestmentReturnDialog(BuildContext context, Investment investment) {
    showDialog(
      context: context,
      builder: (context) => InvestmentReturnDialog(investment: investment),
    ).then((value) {
      if (value == true) {
        // Refresh the investment list
        Provider.of<FinanceProvider>(context, listen: false).notifyListeners();
      }
    });
  }

  void _editInvestment(BuildContext context, Investment investment) {
    showDialog(
      context: context,
      builder: (context) => AddInvestmentDialog(existingInvestment: investment),
    );
  }

  void _confirmDeleteInvestment(BuildContext context, Investment investment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Investment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this investment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final financeData = Provider.of<FinanceProvider>(context, listen: false);
              financeData.deleteInvestment(investment.id);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Investment deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getInvestmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'stocks':
        return Colors.blue;
      case 'mutual funds':
        return Colors.green;
      case 'bonds':
        return Colors.amber;
      case 'real estate':
        return Colors.brown;
      case 'gold':
        return Colors.orange;
      case 'insurance':
        return Colors.purple;
      case 'fixed deposit':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }

  IconData _getInvestmentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'stocks':
        return Icons.show_chart;
      case 'mutual funds':
        return Icons.pie_chart;
      case 'bonds':
        return Icons.account_balance;
      case 'real estate':
        return Icons.home;
      case 'gold':
        return Icons.monetization_on;
      case 'insurance':
        return Icons.security;
      case 'fixed deposit':
        return Icons.savings;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
