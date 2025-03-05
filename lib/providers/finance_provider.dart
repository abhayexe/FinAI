import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_service.dart';
import '../models/transaction.dart';
import './currency_provider.dart';

class FinanceProvider with ChangeNotifier {
  final GeminiService _geminiService;
  List<Transaction> _transactions = [];
  double _income = 50000.0; // Default monthly income
  double _budget = 40000.0; // Default monthly budget

  FinanceProvider(this._geminiService) {
    _loadData();
  }

  double get income => _income;
  double get budget => _budget;
  List<Transaction> get transactions => [..._transactions];

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _income = prefs.getDouble('income') ?? 50000.0;
    _budget = prefs.getDouble('budget') ?? 40000.0;
    
    final transactionsJson = prefs.getStringList('transactions') ?? [];
    _transactions = transactionsJson
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList();
    
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('income', _income);
    await prefs.setDouble('budget', _budget);
    
    final transactionsJson = _transactions
        .map((transaction) => jsonEncode(transaction.toJson()))
        .toList();
    await prefs.setStringList('transactions', transactionsJson);
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

  double getTotalExpenses() {
    return _transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  double getBalance() {
    return _income - getTotalExpenses();
  }

  double getRemainingBudget() {
    return _budget - getTotalExpenses();
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
    return currencyProvider.formatAmount(amount);
  }

  double parseAmount(String text, CurrencyProvider currencyProvider) {
    // Remove currency symbol and any thousand separators
    final cleanText = text.replaceAll(currencyProvider.selectedSymbol, '')
                         .replaceAll(',', '')
                         .replaceAll(' ', '')
                         .trim();
    return double.tryParse(cleanText) ?? 0.0;
  }
}
