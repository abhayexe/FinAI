import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../providers/goals_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/finance_provider.dart';
import '../models/financial_goal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _autoBudgetAdjustEnabled = false;
  bool _isAdjustingBudget = false;

  @override
  void initState() {
    super.initState();
    // Load the auto-adjust setting from shared preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
      setState(() {
        _autoBudgetAdjustEnabled = goalsProvider.isAutoBudgetAdjustEnabled;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Financial Goals',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: Consumer2<GoalsProvider, CurrencyProvider>(
        builder: (context, goalsProvider, currencyProvider, _) {
          final activeGoals = goalsProvider.activeGoals;
          final completedGoals = goalsProvider.completedGoals;
          final hasGoals = activeGoals.isNotEmpty || completedGoals.isNotEmpty;

          return Column(
            children: [
              // Auto-adjust budget toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Budget Adjustment',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Let AI adjust your budget automatically based on your financial goals',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer
                                  .withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isAdjustingBudget
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary),
                            ),
                          )
                        : Switch(
                            value: _autoBudgetAdjustEnabled,
                            onChanged: hasGoals
                                ? (value) =>
                                    _handleToggleChange(value, goalsProvider)
                                : null, // Disable the switch if there are no goals
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                  ],
                ),
              ),

              // Help text when switch is disabled
              if (!hasGoals)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Add at least one financial goal to enable AI budget adjustment',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),

              // Goals list
              Expanded(
                child: hasGoals
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activeGoals.isNotEmpty) ...[
                              Text(
                                'Active Goals',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...activeGoals.map((goal) => _buildGoalCard(
                                  context,
                                  goal,
                                  goalsProvider,
                                  currencyProvider)),
                              const SizedBox(height: 24),
                            ],
                            if (completedGoals.isNotEmpty) ...[
                              Text(
                                'Completed Goals',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...completedGoals.map((goal) => _buildGoalCard(
                                  context,
                                  goal,
                                  goalsProvider,
                                  currencyProvider)),
                            ],
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No financial goals yet',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Set goals to track your financial progress',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddGoalDialog(context);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Goal',
      ),
    );
  }

  // Show dialog when auto-adjust is enabled
  void _showAutoAdjustEnabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'AI Budget Adjustment Enabled',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: const Text(
          'The AI will now automatically adjust your budget based on your financial goals. This will help you allocate funds appropriately to achieve your goals on time.\n\nYou will receive a notification when adjustments are made.\n\nYou can disable this feature at any time.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // Handle toggle switch change
  void _handleToggleChange(bool value, GoalsProvider goalsProvider) async {
    // Only update state if there are goals, otherwise leave it disabled
    if (goalsProvider.goals.isEmpty && value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Add at least one financial goal to enable automatic budget adjustment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _autoBudgetAdjustEnabled = value;
      // If enabling, also show loading
      if (value) {
        _isAdjustingBudget = true;
      }
    });

    // Enable/disable auto budget adjustment
    await goalsProvider.setAutoBudgetAdjustEnabled(value, context);

    // If we enabled it, we can now hide the loading indicator
    if (value && mounted) {
      setState(() {
        _isAdjustingBudget = false;
      });

      // When enabled, show a dialog explaining what will happen
      _showAutoAdjustEnabledDialog(context);
    }
  }

  Widget _buildGoalCard(BuildContext context, FinancialGoal goal,
      GoalsProvider goalsProvider, CurrencyProvider currencyProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: goal.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      goal.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(context, goal, goalsProvider);
                    } else if (value == 'edit') {
                      _showUpdateGoalDialog(
                          context, goal, goalsProvider, currencyProvider);
                    } else if (value == 'complete') {
                      goalsProvider.markGoalAsCompleted(goal.id);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit Goal'),
                      ),
                    ),
                    if (!goal.isCompleted)
                      const PopupMenuItem<String>(
                        value: 'complete',
                        child: ListTile(
                          leading: Icon(Icons.check_circle),
                          title: Text('Mark as Completed'),
                        ),
                      ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete Goal'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              goal.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target: ${currencyProvider.formatAmount(goal.targetAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Current: ${currencyProvider.formatAmount(goal.currentAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: goal.isCompleted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target date:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${goal.targetDate.day}/${goal.targetDate.month}/${goal.targetDate.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 12,
              percent: goal.progressPercentage,
              backgroundColor: Colors.grey[200],
              progressColor: goal.color,
              barRadius: const Radius.circular(12),
              padding: EdgeInsets.zero,
              center: Text(
                '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (!goal.isCompleted)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly need: ${currencyProvider.formatAmount(goal.monthlyAmountNeeded)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${goal.monthsRemaining} months remaining',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            if (goal.isCompleted)
              Align(
                alignment: Alignment.center,
                child: Chip(
                  backgroundColor: Colors.green,
                  label: Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  avatar: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, FinancialGoal goal, GoalsProvider goalsProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Goal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text('Are you sure you want to delete "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              goalsProvider.deleteGoal(goal.id, context);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Goal "${goal.title}" deleted'),
                  backgroundColor: Colors.red,
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'About Financial Goals',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Financial goals help you track your progress towards important financial milestones.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Set realistic and achievable goals'),
            Text('• Break large goals into smaller milestones'),
            Text('• Regularly update your progress'),
            Text('• Adjust your budget to support your goals'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showUpdateGoalDialog(BuildContext context, FinancialGoal goal,
      GoalsProvider goalsProvider, CurrencyProvider currencyProvider) {
    final TextEditingController currentAmountController =
        TextEditingController(text: goal.currentAmount.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Update Progress',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              goal.title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currentAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Current Progress',
                prefixIcon: const Icon(Icons.savings),
                prefixText: currencyProvider.selectedSymbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText:
                    'Target: ${currencyProvider.formatAmount(goal.targetAmount)}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(currentAmountController.text
                      .replaceAll(RegExp(r'[^\d.]'), '')) ??
                  0.0;
              goalsProvider.updateGoalProgress(goal.id, amount, context);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Progress updated for "${goal.title}"'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
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
              'Add Financial Goal',
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
                      prefixText:
                          Provider.of<CurrencyProvider>(context, listen: false)
                              .selectedSymbol,
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
