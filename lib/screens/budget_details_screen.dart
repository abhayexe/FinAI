import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';

class BudgetDetailsScreen extends StatelessWidget {
  const BudgetDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Budget Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer2<FinanceProvider, CurrencyProvider>(
        builder: (ctx, financeData, currencyData, _) {
          final budget = financeData.budget;
          final totalExpenses = financeData.getTotalExpenses();
          final remainingBudget = financeData.getRemainingBudget();
          final percentUsed = budget > 0 ? (totalExpenses / budget) : 0.0;
          final clampedPercent = percentUsed.clamp(0.0, 1.0);
          final categoryTotals = financeData.getCategoryTotals();
          
          // Sort categories by amount spent (descending)
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, financeData, currencyData),
                const SizedBox(height: 24),
                Text(
                  'Spending by Category',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),
                ...sortedCategories.map((entry) => 
                  _buildCategoryItem(
                    context, 
                    entry.key, 
                    entry.value, 
                    budget, 
                    currencyData,
                  ),
                ),
                const SizedBox(height: 24),
                _buildBudgetTips(context, clampedPercent),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, 
    FinanceProvider financeData, 
    CurrencyProvider currencyData
  ) {
    final budget = financeData.budget;
    final totalExpenses = financeData.getTotalExpenses();
    final remainingBudget = financeData.getRemainingBudget();
    final percentUsed = budget > 0 ? (totalExpenses / budget) : 0.0;
    final clampedPercent = percentUsed.clamp(0.0, 1.0);
    final recurringExpensesTotal = financeData.getRecurringExpensesTotal();
    final recurringPercentage = budget > 0 ? (recurringExpensesTotal / budget) * 100 : 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Budget:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  currencyData.formatAmount(budget),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Spent:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  currencyData.formatAmount(totalExpenses),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Text(
                  currencyData.formatAmount(remainingBudget),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: remainingBudget >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Budget Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              lineHeight: 16.0,
              percent: clampedPercent,
              center: Text(
                '${(clampedPercent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              progressColor: _getProgressColor(clampedPercent),
              backgroundColor: Colors.grey[200],
              barRadius: const Radius.circular(8),
              animation: true,
              animationDuration: 1000,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recurring Expenses:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  currencyData.formatAmount(recurringExpensesTotal),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recurring expenses make up ${recurringPercentage.toStringAsFixed(1)}% of your budget',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String category,
    double amount,
    double budget,
    CurrencyProvider currencyData,
  ) {
    final percent = budget > 0 ? (amount / budget).clamp(0.0, 1.0) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              Text(
                currencyData.formatAmount(amount),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(percent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 10.0,
            percent: percent,
            progressColor: _getProgressColor(percent),
            backgroundColor: Colors.grey[200],
            barRadius: const Radius.circular(5),
            padding: EdgeInsets.zero,
          ),
          Text(
            '${(percent * 100).toStringAsFixed(1)}% of budget',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTips(BuildContext context, double percentUsed) {
    String title;
    String message;
    IconData icon;
    Color color;

    if (percentUsed < 0.5) {
      title = 'Great job!';
      message = 'You\'re well within your budget. Consider saving the extra money or investing it for future growth.';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (percentUsed < 0.8) {
      title = 'On track';
      message = 'You\'re managing your budget well, but keep an eye on your spending for the rest of the month.';
      icon = Icons.trending_flat;
      color = Colors.orange;
    } else {
      title = 'Budget alert';
      message = 'You\'re close to or exceeding your budget. Consider reviewing your expenses and cutting back where possible.';
      icon = Icons.warning;
      color = Colors.red;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent < 0.5) {
      return Colors.green;
    } else if (percent < 0.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
