import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/add_transaction.dart';
import '../widgets/transaction_list.dart';
import '../widgets/budget_summary.dart';
import '../widgets/spending_chart.dart';
import '../widgets/recurring_expense_dialog.dart';
import '../widgets/recurring_expense_edit_dialog.dart';
import '../widgets/loan_details_dialog.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFooter = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
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
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                        final recurringExpenses = financeData.getRecurringTransactions();
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
                                  constraints: const BoxConstraints(maxHeight: 300),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: recurringExpenses.take(3).length,
                                    itemBuilder: (context, index) {
                                      final expense = recurringExpenses[index];
                                      final frequency = _normalizeFrequencyDisplay(expense.recurringFrequency);
                                      final day = expense.recurringDay != null ? 
                                                ' (Day ${expense.recurringDay})' : '';
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          leading: const Icon(Icons.repeat, color: Colors.orange),
                                          title: Text(expense.title),
                                          subtitle: Text(frequency + day),
                                          trailing: Text(
                                            Provider.of<CurrencyProvider>(context, listen: false)
                                                .formatAmount(expense.amount),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
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
                                  ),
                                ),
                                if (recurringExpenses.length > 3)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => AllRecurringExpensesScreen(),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'View All Recurring Expenses',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_forward, size: 20),
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
                    // Footer
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
    return Consumer2<FinanceProvider, CurrencyProvider>(
      builder: (ctx, financeData, currencyProvider, _) {
        final totalBalance = financeData.getBalance();
        final totalExpenses = financeData.getTotalExpenses();
        final totalIncome = financeData.income;

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
                      Column(
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
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SettingsScreen()),
                              );
                            },
                            tooltip: 'Settings',
                          ),
                          IconButton(
                            icon: Icon(
                              SupabaseService.isAuthenticated ? Icons.logout : Icons.login,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              if (SupabaseService.isAuthenticated) {
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(
                                      'Logout',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                    content: const Text('Are you sure you want to logout?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                ) ?? false;

                                if (shouldLogout) {
                                  await SupabaseService.signOut();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => AuthScreen()),
                                    (route) => false,
                                  );
                                }
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => AuthScreen()),
                                );
                              }
                            },
                            tooltip: SupabaseService.isAuthenticated ? 'Logout' : 'Login',
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
      width: MediaQuery.of(context).size.width * 0.43, // Set a fixed width based on screen size
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
          Expanded(  // Wrap in Expanded to prevent overflow
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
                    fontSize: 14,  // Slightly smaller font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,  // Add ellipsis if text is too long
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
                      final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
                      
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
          const SizedBox(height: 16), // Add spacing for the third row
          // Third row with Stock Market button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                'Stock\nMarket',
                Icons.show_chart,
                Colors.indigo,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StockMarketScreen()),
                  );
                },
              ),
              _buildActionButton(
                context,
                'Chat\nRooms',
                Icons.chat,
                Colors.pink,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatRoomsScreen()),
                  );
                },
              ),
              _buildActionButton(
                context,
                'Premium\nAdvisor',
                Icons.workspace_premium,
                Colors.amber.shade700,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SubscriptionScreen()),
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
}
