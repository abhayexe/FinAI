import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/bank_account_provider.dart';
import '../models/bank_account.dart';
import '../widgets/add_transaction.dart';
import '../widgets/transaction_list.dart';
import '../widgets/budget_summary.dart';
import '../widgets/spending_chart.dart';
import '../widgets/recurring_expense_dialog.dart';
import '../widgets/recurring_expense_edit_dialog.dart';
import '../widgets/loan_details_dialog.dart';
import '../widgets/investment_list.dart';
import '../widgets/add_investment.dart';
import '../widgets/budget_adjustment_notification.dart';
import '../services/supabase_service.dart';
import 'ai_advice_screen.dart';
import 'bank_connection_screen.dart';
import 'settings_screen.dart';
import 'ai_predictions_screen.dart';
import 'help_screen.dart';
import 'feedback_screen.dart';
import 'auth_screen.dart';
import 'all_recurring_expenses.dart';
import 'stock_market_screen.dart';
import 'chat_rooms_screen.dart';
import 'subscription_screen.dart';
import 'profile_screen.dart';
import 'accounts_screen.dart';
import 'transfer_screen.dart';
import 'transfer_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFooter = false;
  bool _showBudgetAdjustmentNotification = false;
  double _oldBudget = 0.0;
  double _newBudget = 0.0;
  String _aiExplanation = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      // Check if we're at the bottom of the list
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // Load more data
      }
    });

    // Load user profile and bank accounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load bank accounts
      Provider.of<BankAccountProvider>(context, listen: false).loadAccounts();

      // Check for budget adjustments after loading data
      // final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
      // goalsProvider.checkForBudgetAdjustmentNotification();
    });

    // Check for budget adjustment notifications on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
      final budgetAdjustment = goalsProvider.getLastBudgetAdjustment();

      if (budgetAdjustment != null && !budgetAdjustment.wasShown) {
        setState(() {
          _showBudgetAdjustmentNotification = true;
          _oldBudget = budgetAdjustment.oldBudget;
          _newBudget = budgetAdjustment.newBudget;
          _aiExplanation = budgetAdjustment.explanation;
        });
        goalsProvider.markBudgetAdjustmentAsShown();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_showFooter) setState(() => _showFooter = true);
    } else {
      if (_showFooter) setState(() => _showFooter = false);
    }
  }

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

  void _showAdjustmentDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Budget Adjustment Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Explanation:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _aiExplanation,
                style: const TextStyle(
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Consumer<FinanceProvider>(
            builder: (ctx, financeData, _) {
              final totalExpenses = financeData.getTotalExpenses();
              final income = financeData.income;
              final isOverspending = totalExpenses > income;

              if (isOverspending) {
                return Container(
                  width: double.infinity,
                  color: Colors.amber.shade50,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade800,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overspending Alert',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Your expenses (${Provider.of<CurrencyProvider>(context, listen: false).formatAmount(totalExpenses)}) exceed your income (${Provider.of<CurrencyProvider>(context, listen: false).formatAmount(income)}). Consider reviewing your spending.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        color: Colors.amber.shade800,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AIAdviceScreen()),
                          );
                        },
                        tooltip: 'Get AI Advice',
                      ),
                    ],
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),

          // Budget adjustment notification
          if (_showBudgetAdjustmentNotification)
            BudgetAdjustmentNotification(
              oldBudget: _oldBudget,
              newBudget: _newBudget,
              onDetailsPressed: () => _showAdjustmentDetailsDialog(context),
              onDismiss: () {
                setState(() {
                  _showBudgetAdjustmentNotification = false;
                });
              },
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Implement refresh logic if needed
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    // Premium subscription button
                    Consumer<SubscriptionProvider>(
                      builder: (context, subscriptionProvider, _) {
                        final isPremium = subscriptionProvider.isPremiumUser;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ElevatedButton(
                            onPressed: isPremium
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => SubscriptionScreen()),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPremium
                                  ? Colors.green.shade700
                                  : Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    isPremium
                                        ? Icons.verified
                                        : Icons.workspace_premium,
                                    size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  isPremium
                                      ? 'You are a Premium User'
                                      : 'Upgrade to Premium',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BudgetSummary(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SpendingChart(),
                    ),
                    Consumer<FinanceProvider>(
                      builder: (context, financeData, _) {
                        final investments = financeData.getRecentInvestments();
                        if (investments.isNotEmpty) {
                          return InvestmentList(
                            investments: investments,
                            showHeader: true,
                            isCompact: true,
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    Consumer<FinanceProvider>(
                      builder: (context, financeData, _) {
                        final recurringExpenses =
                            financeData.getRecurringTransactions();
                        if (recurringExpenses.isNotEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recurring Expenses',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 300),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: recurringExpenses.take(3).length,
                                    itemBuilder: (context, index) {
                                      final expense = recurringExpenses[index];
                                      final frequency =
                                          _normalizeFrequencyDisplay(
                                              expense.recurringFrequency);
                                      final day = expense.recurringDay != null
                                          ? ' (Day ${expense.recurringDay})'
                                          : '';
                                      return Card(
                                        elevation: 2,
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: const Icon(Icons.repeat,
                                              color: Colors.orange),
                                          title: Text(expense.title),
                                          subtitle: Text(frequency + day),
                                          trailing: Text(
                                            Provider.of<CurrencyProvider>(
                                                    context,
                                                    listen: false)
                                                .formatAmount(expense.amount),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) =>
                                                  RecurringExpenseEditDialog(
                                                expense: expense,
                                                onDelete: (expense) {
                                                  Provider.of<FinanceProvider>(
                                                          context,
                                                          listen: false)
                                                      .deleteRecurringExpense(
                                                          expense);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (recurringExpenses.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AllRecurringExpensesScreen(),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'View All Recurring Expenses',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_forward,
                                              size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transactions',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TransactionList(),

                    // Add Bank Accounts Section
                    _buildBankAccountsSection(),

                    // Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, -1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.code,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Built By Team npm run devs',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFooterButton(
                                context,
                                icon: Icons.help_outline,
                                label: 'Help',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HelpScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 20),
                              _buildFooterButton(
                                context,
                                icon: Icons.feedback_outlined,
                                label: 'Feedback',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FeedbackScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => AddTransaction(),
          );
        },
        tooltip: 'Add Transaction',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer3<FinanceProvider, CurrencyProvider, BankAccountProvider>(
      builder: (ctx, financeData, currencyProvider, bankAccountProvider, _) {
        final totalBalance = bankAccountProvider.totalBalance;
        final totalExpenses = financeData.getTotalExpenses();
        final totalIncome = financeData.income;
        final transactionIncome = financeData.getTotalIncome();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FinAI',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Balance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyProvider.formatAmount(totalBalance),
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Profile button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ProfileScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: FutureBuilder<Map<String, dynamic>?>(
                                future: SupabaseService
                                    .getOrCreateCurrentUserProfile(),
                                builder: (context, snapshot) {
                                  final fullName =
                                      snapshot.data?['full_name'] ?? 'U';
                                  return Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon:
                                const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => SettingsScreen()),
                              );
                            },
                            tooltip: 'Settings',
                          ),
                          IconButton(
                            icon: Icon(
                              SupabaseService.isAuthenticated
                                  ? Icons.logout
                                  : Icons.login,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              if (SupabaseService.isAuthenticated) {
                                final shouldLogout = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(
                                          'Logout',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        content: const Text(
                                            'Are you sure you want to logout?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Logout'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;

                                if (shouldLogout) {
                                  await SupabaseService.signOut();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) => AuthScreen()),
                                    (route) => false,
                                  );
                                }
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => AuthScreen()),
                                );
                              }
                            },
                            tooltip: SupabaseService.isAuthenticated
                                ? 'Logout'
                                : 'Login',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceItem(
                        context,
                        'Income',
                        currencyProvider.formatAmount(totalIncome),
                        Icons.arrow_upward,
                        Colors.green,
                      ),
                      _buildBalanceItem(
                        context,
                        'Expenses',
                        currencyProvider.formatAmount(totalExpenses),
                        Icons.arrow_downward,
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width *
          0.43, // Set a fixed width based on screen size
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            // Wrap in Expanded to prevent overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: GoogleFonts.poppins(
                    fontSize: 14, // Slightly smaller font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow:
                      TextOverflow.ellipsis, // Add ellipsis if text is too long
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // First row with 3 buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                'Add\nTransaction',
                Icons.add,
                Colors.green,
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddTransaction(),
                  );
                },
              ),
              _buildActionButton(
                context,
                'AI Advice',
                Icons.psychology,
                Colors.purple,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AIAdviceScreen()),
                  );
                },
              ),
              _buildActionButton(
                context,
                'Recurring',
                Icons.repeat,
                Colors.orange,
                () {
                  showDialog(
                    context: context,
                    builder: (context) => const RecurringExpenseDialog(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16), // Add spacing between rows
          // Second row with 3 buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                'Bank\nConnect',
                Icons.account_balance,
                Colors.blue,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BankConnectionScreen()),
                  );
                },
              ),
              _buildActionButton(
                context,
                'AI\nPredictions',
                Icons.trending_up,
                Colors.teal,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AIPredictionsScreen()),
                  );
                },
              ),
              _buildActionButton(
                context,
                'Loan',
                Icons.monetization_on,
                Colors.amber,
                () {
                  showDialog(
                    context: context,
                    builder: (context) => LoanDetailsDialog(),
                  ).then((result) {
                    if (result != null) {
                      final financeProvider =
                          Provider.of<FinanceProvider>(context, listen: false);

                      // Add loan amount to balance
                      financeProvider.addTransaction(result['loanTransaction']);

                      // Add recurring interest expense
                      financeProvider.addTransaction(result['interestExpense']);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loan added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16), // Add spacing between rows
          // Third row with 3 buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                'Investments',
                Icons.account_balance_wallet,
                Colors.indigo,
                () {
                  _showAddInvestmentDialog(context);
                },
              ),
              _buildActionButton(
                context,
                'Stocks',
                Icons.show_chart,
                Colors.blue.shade800,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StockMarketScreen()),
                  );
                },
              ),
              _buildActionButton(
                context,
                'Chat',
                Icons.chat,
                Colors.pink,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatRoomsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInvestmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddInvestmentDialog(),
    );
  }

  Widget _buildFooterButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountsSection() {
    return Consumer<BankAccountProvider>(
      builder: (ctx, bankAccountProvider, _) {
        final accounts = bankAccountProvider.accounts;
        final selectedAccount = bankAccountProvider.selectedAccount;
        final totalBalance = bankAccountProvider.totalBalance;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bank Accounts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.swap_horiz),
                          tooltip: 'Transfer Money',
                          onPressed: accounts.length >= 2
                              ? () => Navigator.of(context)
                                  .pushNamed(TransferScreen.routeName)
                              : null,
                        ),
                        IconButton(
                          icon: Icon(Icons.history),
                          tooltip: 'Transfer History',
                          onPressed: () => Navigator.of(context)
                              .pushNamed(TransferHistoryScreen.routeName),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                if (accounts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No accounts added yet',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AccountsScreen.routeName),
                          icon: Icon(Icons.add),
                          label: Text('Add Account'),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total Balance:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '\$${totalBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: accounts.length > 3
                              ? accounts.length + 1
                              : accounts.length,
                          itemBuilder: (ctx, index) {
                            if (index == accounts.length) {
                              // View All button at the end
                              return Container(
                                width: 100,
                                margin: EdgeInsets.only(right: 8),
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context)
                                      .pushNamed(AccountsScreen.routeName),
                                  child: Text('View All'),
                                ),
                              );
                            }

                            final account = accounts[index];
                            return GestureDetector(
                              onTap: () =>
                                  bankAccountProvider.selectAccount(account.id),
                              child: Container(
                                width: 140,
                                margin: EdgeInsets.only(right: 12),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedAccount?.id == account.id
                                      ? Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedAccount?.id == account.id
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getIconForAccountType(account.type),
                                          size: 16,
                                          color: _getColorForAccountType(
                                              account.type),
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            account.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '\$${account.balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AccountsScreen.routeName),
                            icon: Icon(Icons.account_balance),
                            label: Text('Manage Accounts'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          if (accounts.length >= 2)
                            ElevatedButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed(TransferScreen.routeName),
                              icon: Icon(Icons.swap_horiz),
                              label: Text('Transfer'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                        ],
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

  IconData _getIconForAccountType(BankAccountType type) {
    switch (type) {
      case BankAccountType.checking:
        return Icons.account_balance;
      case BankAccountType.savings:
        return Icons.savings;
      case BankAccountType.investment:
        return Icons.trending_up;
      case BankAccountType.credit:
        return Icons.credit_card;
      default:
        return Icons.account_balance; // Default fallback
    }
  }

  Color _getColorForAccountType(BankAccountType type) {
    switch (type) {
      case BankAccountType.checking:
        return Colors.blue;
      case BankAccountType.savings:
        return Colors.green;
      case BankAccountType.investment:
        return Colors.purple;
      case BankAccountType.credit:
        return Colors.orange;
      default:
        return Colors.blue; // Default fallback
    }
  }
}
