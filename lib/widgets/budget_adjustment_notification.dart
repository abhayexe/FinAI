import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/currency_provider.dart';
import 'package:provider/provider.dart';

class BudgetAdjustmentNotification extends StatelessWidget {
  final double oldBudget;
  final double newBudget;
  final VoidCallback onDetailsPressed;
  final VoidCallback onDismiss;

  const BudgetAdjustmentNotification({
    required this.oldBudget,
    required this.newBudget,
    required this.onDetailsPressed,
    required this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);
    final symbol = currencyProvider.selectedSymbol;
    final percentChange =
        ((newBudget - oldBudget) / oldBudget * 100).abs().toStringAsFixed(1);
    final isIncrease = newBudget > oldBudget;

    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Budget Adjustment',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your budget has been ${isIncrease ? 'increased' : 'reduced'} by $percentChange% to better align with your financial goals.',
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous Budget:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$symbol${oldBudget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward,
                  color: Colors.grey[500],
                  size: 16,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'New Budget:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$symbol${newBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isIncrease
                            ? Colors.green
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.orangeAccent
                                : Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('View Details'),
              onPressed: onDetailsPressed,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
