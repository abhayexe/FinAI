import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/goals_provider.dart';
import '../models/financial_goal.dart';
import '../screens/budget_details_screen.dart';
import '../screens/goals_screen.dart';

class BudgetSummary extends StatefulWidget {
  const BudgetSummary({super.key});

  @override
  _BudgetSummaryState createState() => _BudgetSummaryState();
}

class _BudgetSummaryState extends State<BudgetSummary> {
  void _showWarningDialog(
      BuildContext context, String message, VoidCallback onContinue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Warning',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onContinue();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FinanceProvider, CurrencyProvider>(
      builder: (ctx, financeData, currencyData, _) {
        final budget = financeData.budget;
        final totalExpenses = financeData.getTotalExpenses();
        final remainingBudget = financeData.getRemainingBudget();
        final percentUsed = budget > 0 ? (totalExpenses / budget) : 0.0;
        final clampedPercent = percentUsed.clamp(0.0, 1.0);

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
                  'Monthly Budget',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircularPercentIndicator(
                      radius: 70.0,
                      lineWidth: 12.0,
                      percent: clampedPercent,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(clampedPercent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Used',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      progressColor: _getProgressColor(clampedPercent),
                      backgroundColor: Colors.grey[200]!,
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                      animationDuration: 1000,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBudgetItem(
                          context,
                          'Budget',
                          financeData.formatAmount(budget, currencyData),
                          Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        _buildBudgetItem(
                          context,
                          'Spent',
                          financeData.formatAmount(totalExpenses, currencyData),
                          Colors.orange,
                        ),
                        const SizedBox(height: 12),
                        _buildBudgetItem(
                          context,
                          'Remaining',
                          financeData.formatAmount(
                              remainingBudget, currencyData),
                          remainingBudget >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        'Update Budget',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _showUpdateBudgetDialog(
                          context, financeData, currencyData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(120, 36),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.insights, size: 16),
                      label: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BudgetDetailsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(120, 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.flag, size: 16),
                      label: Text(
                        'Set Goals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _showSetGoalsDialog(
                          context, financeData, currencyData),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(140, 36),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: Text(
                        'View Goals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GoalsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(140, 36),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetItem(
      BuildContext context, String label, String value, Color color) {
    return Row(
      children: [
        Icon(
          Icons.account_balance_wallet,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ],
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

  void _showUpdateBudgetDialog(BuildContext context,
      FinanceProvider financeData, CurrencyProvider currencyData) {
    final TextEditingController budgetController = TextEditingController(
      text: financeData.budget.toString(),
    );
    final TextEditingController incomeController = TextEditingController(
      text: financeData.income.toString(),
    );

    void updateValues() {
      final newBudget = double.tryParse(
              budgetController.text.replaceAll(RegExp(r'[^\d.]'), '')) ??
          0.0;
      final newIncome = double.tryParse(
              incomeController.text.replaceAll(RegExp(r'[^\d.]'), '')) ??
          0.0;
      final balance = financeData.getBalance();

      // Check if budget exceeds balance
      if (newBudget > balance) {
        _showErrorDialog(
          context,
          'Your budget (${currencyData.formatAmount(newBudget)}) cannot exceed your available balance (${currencyData.formatAmount(balance)}). Please set a lower budget.',
        );
        return;
      }

      // Check if budget exceeds income
      if (newBudget > newIncome) {
        _showWarningDialog(
          context,
          'Your budget (${currencyData.formatAmount(newBudget)}) exceeds your income (${currencyData.formatAmount(newIncome)}). This might lead to financial strain.',
          () {
            financeData.updateBudget(newBudget);
            financeData.setIncome(newIncome);
            Navigator.of(context).pop();
          },
        );
      } else {
        financeData.updateBudget(newBudget);
        financeData.setIncome(newIncome);
        Navigator.of(context).pop();
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Update Financial Info',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: incomeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Income',
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: currencyData.selectedSymbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monthly Budget',
                prefixIcon: const Icon(Icons.account_balance_wallet),
                prefixText: currencyData.selectedSymbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText:
                    'Available balance: ${currencyData.formatAmount(financeData.getBalance())}',
                helperStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[600]),
              ),
              onChanged: (value) {
                final budget =
                    double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ??
                        0.0;
                final income = double.tryParse(incomeController.text
                        .replaceAll(RegExp(r'[^\d.]'), '')) ??
                    0.0;
                final balance = financeData.getBalance();

                if (budget > balance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Error: Budget cannot exceed available balance'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (budget > income) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Warning: Budget exceeds income'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: updateValues,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  // Show dialog to set financial goals
  void _showSetGoalsDialog(BuildContext context, FinanceProvider financeData,
      CurrencyProvider currencyData) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    // Initial values for the date picker
    final now = DateTime.now();
    DateTime targetDate = DateTime(
        now.year, now.month + 3, now.day); // Default: 3 months from now

    // Default colors for goal selection
    final List<Color> goalColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    Color selectedColor = goalColors.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Set Financial Goal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Goal Title',
                      hintText: 'e.g., New Car, Pay Off Loan',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your financial goal',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Target Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      prefixText: currencyData.selectedSymbol,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(now.year + 10),
                      );
                      if (picked != null && picked != targetDate) {
                        setState(() {
                          targetDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Target Date',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${targetDate.day}/${targetDate.month}/${targetDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Goal Color:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: goalColors.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: color == selectedColor
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: color == selectedColor
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validate inputs
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a goal title')),
                    );
                    return;
                  }

                  final amount = double.tryParse(
                      amountController.text.replaceAll(RegExp(r'[^\d.]'), ''));
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid amount')),
                    );
                    return;
                  }

                  // Create the goal object
                  final goal = FinancialGoal(
                    title: titleController.text,
                    description: descriptionController.text.isEmpty
                        ? 'No description provided'
                        : descriptionController.text,
                    targetAmount: amount,
                    targetDate: targetDate,
                    color: selectedColor,
                  );

                  // Add the goal using the provider
                  final goalsProvider =
                      Provider.of<GoalsProvider>(context, listen: false);
                  goalsProvider.addGoal(goal, context);

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Financial goal "${goal.title}" added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Goal'),
              ),
            ],
          );
        },
      ),
    );
  }
}
