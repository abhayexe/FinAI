import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../models/transaction.dart';
import '../models/investment.dart';
import './currency_provider.dart';

class FinanceProvider with ChangeNotifier {
  final GeminiService _geminiService;
  List<Transaction> _transactions = [];
  List<Investment> _investments = [];
  double _income = 50000.0; // Default monthly income
  double _budget = 40000.0; // Default monthly budget
  double _savingsGoal = 0;
  List<Map<String, dynamic>> _loans = [];

  FinanceProvider(this._geminiService) {
    _loadData();
  }

  double get income => _income;
  double get budget => _budget;
  double get savingsGoal => _savingsGoal;
  List<Transaction> get transactions => [..._transactions];
  List<Investment> get investments => [..._investments];

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _income = prefs.getDouble('income') ?? 50000.0;
    _budget = prefs.getDouble('budget') ?? 40000.0;
    _savingsGoal = prefs.getDouble('savingsGoal') ?? 0;
    
    final transactionsJson = prefs.getString('transactions');
    final investmentsJson = prefs.getString('investments');
    final loansJson = prefs.getString('loans');

    if (transactionsJson != null) {
      final List<dynamic> decodedTransactions = jsonDecode(transactionsJson);
      _transactions = decodedTransactions
          .map((item) => Transaction.fromJson(item))
          .toList();
    }

    if (investmentsJson != null) {
      final List<dynamic> decodedInvestments = jsonDecode(investmentsJson);
      _investments = decodedInvestments
          .map((item) => Investment.fromJson(item))
          .toList();
    }

    if (loansJson != null) {
      _loans = jsonDecode(loansJson);
    }
    
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = jsonEncode(_transactions.map((tx) => tx.toJson()).toList());
    final investmentsJson = jsonEncode(_investments.map((inv) => inv.toJson()).toList());
    final loansJson = jsonEncode(_loans);

    await prefs.setString('transactions', transactionsJson);
    await prefs.setString('investments', investmentsJson);
    await prefs.setDouble('income', _income);
    await prefs.setDouble('budget', _budget);
    await prefs.setDouble('savingsGoal', _savingsGoal);
    await prefs.setString('loans', loansJson);
  }

  void setIncome(double amount) {
    _income = amount;
    _saveData();
    notifyListeners();
  }

  void updateBudget(double amount) {
    _budget = amount;
    _saveData();
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    _transactions.add(transaction);
    _saveData();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteRecurringExpense(Transaction transaction) async {
    _transactions.removeWhere((tx) => 
      tx.isRecurring &&
      tx.title == transaction.title && 
      tx.amount == transaction.amount && 
      tx.recurringFrequency == transaction.recurringFrequency &&
      tx.recurringDay == transaction.recurringDay
    );
    notifyListeners();
    await _saveData();
  }

  void updateTransaction(Transaction transaction) {
    final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _saveData();
      notifyListeners();
    }
  }

  void addInvestment(Investment investment) {
    _investments.add(investment);
    
    // When adding an investment, deduct the amount from the balance
    // by adding a transaction for the investment
    final transaction = Transaction(
      id: DateTime.now().toString(),
      title: 'Investment: ${investment.title}',
      amount: investment.amount,
      date: DateTime.now(),
      category: 'Investment',
      isIncome: false,
      isRecurring: false,
    );
    
    // Add the transaction (this will affect the balance)
    addTransaction(transaction);
    
    _saveData();
    notifyListeners();
  }

  void updateInvestment(Investment investment) {
    final index = _investments.indexWhere((inv) => inv.id == investment.id);
    if (index != -1) {
      _investments[index] = investment;
      _saveData();
      notifyListeners();
    }
  }

  void deleteInvestment(String id) {
    _investments.removeWhere((inv) => inv.id == id);
    _saveData();
    notifyListeners();
  }

  double getTotalExpenses() {
    return _transactions
        .where((tx) => !tx.isIncome) // Only count expenses
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getTotalIncome() {
    return _transactions
        .where((tx) => tx.isIncome) // Only count income
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getBalance() {
    // Balance starts with monthly income, adds/subtracts transactions
    return _income + getTotalIncome() - getTotalExpenses();
  }

  double getRemainingBudget() {
    return _budget - getTotalExpenses() - getTotalInvestments();
  }

  List<Transaction> getRecentTransactions() {
    final nonRecurringTransactions = _transactions
        .where((tx) => !tx.isRecurring)
        .toList();
    nonRecurringTransactions.sort((a, b) => b.date.compareTo(a.date));
    return nonRecurringTransactions.take(5).toList();
  }

  List<Transaction> getRecurringTransactions() {
    return _transactions
        .where((tx) => tx.isRecurring)
        .toList();
  }

  List<Investment> getRecentInvestments() {
    final sortedInvestments = [..._investments];
    sortedInvestments.sort((a, b) => b.date.compareTo(a.date));
    return sortedInvestments.take(5).toList();
  }

  double getTotalInvestments() {
    return _investments.fold(0, (sum, investment) => sum + investment.amount);
  }

  Map<String, double> getCategoryTotals() {
    final Map<String, double> categoryTotals = {};
    
    for (final transaction in _transactions) {
      final category = transaction.category;
      final amount = transaction.amount;
      
      if (categoryTotals.containsKey(category)) {
        categoryTotals[category] = categoryTotals[category]! + amount;
      } else {
        categoryTotals[category] = amount;
      }
    }
    
    return categoryTotals;
  }

  String getTopSpendingCategory() {
    final categoryTotals = getCategoryTotals();
    if (categoryTotals.isEmpty) return 'No data';
    
    var topCategory = categoryTotals.entries.first;
    for (var entry in categoryTotals.entries) {
      if (entry.value > topCategory.value) {
        topCategory = entry;
      }
    }
    return topCategory.key;
  }

  double getAverageMonthlySpending() {
    if (_transactions.isEmpty) return 0;
    
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);
    
    final monthlyTransactions = _transactions
        .where((tx) => tx.date.isAfter(oneMonthAgo))
        .toList();
    
    if (monthlyTransactions.isEmpty) return 0;
    
    return monthlyTransactions.fold(
      0.0,
      (sum, tx) => sum + tx.amount,
    ) / monthlyTransactions.length;
  }

  double getRecurringExpensesTotal() {
    return _transactions
        .where((tx) => tx.isRecurring)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<String> getFinancialAdvice({String? specificQuestion, required CurrencyProvider currencyProvider}) async {
    try {
      final advice = await _geminiService.getFinancialAdvice(
        income: _income,
        expenses: getTotalExpenses(),
        budget: _budget,
        transactions: _transactions,
        currencyProvider: currencyProvider,
        specificQuestion: specificQuestion,
      );
      return advice;
    } catch (e) {
      return 'Unable to get AI advice at the moment. Please try again later.';
    }
  }

  Future<String> getFinancialPredictions(CurrencyProvider currencyProvider) async {
    try {
      return await _geminiService.getFinancialPredictions(
        transactions: _transactions,
        recurringExpenses: getRecurringTransactions(),
        totalBalance: getTotalExpenses(),
        monthlyIncome: _income,
        currencyProvider: currencyProvider,
      );
    } catch (e) {
      return 'Error getting predictions: $e';
    }
  }

  String formatAmount(double amount, CurrencyProvider currencyProvider) {
    final prefix = amount > 0 ? '+' : '';
    return prefix + currencyProvider.formatAmount(amount);
  }

  String formatTransactionAmount(Transaction transaction, CurrencyProvider currencyProvider) {
    final prefix = transaction.isIncome ? '+' : '-';
    final formattedAmount = currencyProvider.formatAmount(transaction.amount);
    return prefix + formattedAmount;
  }

  String formatInvestmentAmount(Investment investment, CurrencyProvider currencyProvider) {
    return currencyProvider.formatAmount(investment.amount);
  }

  double parseAmount(String text, CurrencyProvider currencyProvider) {
    final cleanText = text.replaceAll(currencyProvider.selectedSymbol, '')
                         .replaceAll(',', '')
                         .replaceAll(' ', '')
                         .trim();
    return double.tryParse(cleanText) ?? 0.0;
  }

  void addInvestmentReturn(String investmentId, double returnAmount) {
    // Find the investment to get its details
    final investment = _investments.firstWhere((inv) => inv.id == investmentId);
    final originalAmount = investment.amount;
    
    // Calculate profit or loss
    final profitOrLoss = returnAmount - originalAmount;
    final isProfitable = profitOrLoss >= 0;
    
    // Add a transaction for the profit/loss
    final transaction = Transaction(
      id: DateTime.now().toString(),
      title: isProfitable 
          ? 'Profit: ${investment.title}'
          : 'Loss: ${investment.title}',
      amount: profitOrLoss.abs(), // Use absolute value for the amount
      date: DateTime.now(),
      category: 'Investment Return',
      isIncome: isProfitable, // If profit, it's income; if loss, it's expense
      isRecurring: false,
    );
    
    // Add the transaction
    addTransaction(transaction);
    
    // Remove the investment from the list
    _investments.removeWhere((inv) => inv.id == investmentId);
    
    // Save the updated data
    _saveData();
    notifyListeners();
  }
}
