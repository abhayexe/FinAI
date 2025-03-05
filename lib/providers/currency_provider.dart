import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyProvider with ChangeNotifier {
  String _selectedCurrency = 'INR';
  Map<String, double> _exchangeRates = {};
  
  // Common currencies with their symbols
  final Map<String, String> currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'SGD': 'S\$',
    'AED': 'د.إ',
  };

  String get selectedCurrency => _selectedCurrency;
  String get selectedSymbol => currencySymbols[_selectedCurrency] ?? _selectedCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;

  CurrencyProvider() {
    _loadSavedCurrency();
    _fetchExchangeRates();
  }

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('selectedCurrency') ?? 'INR';
    notifyListeners();
  }

  Future<void> _fetchExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/INR')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        _exchangeRates = rates.map((key, value) => MapEntry(key, value.toDouble()));
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
    }
  }

  Future<void> changeCurrency(String newCurrency) async {
    if (_selectedCurrency != newCurrency) {
      _selectedCurrency = newCurrency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedCurrency', newCurrency);
      notifyListeners();
    }
  }

  double convertAmount(double amount, {String? fromCurrency}) {
    fromCurrency ??= 'INR';
    if (_exchangeRates.isEmpty || fromCurrency == _selectedCurrency) {
      return amount;
    }

    // Convert to INR first (if not already in INR)
    double amountInINR = amount;
    if (fromCurrency != 'INR') {
      amountInINR = amount / (_exchangeRates[fromCurrency] ?? 1);
    }

    // Convert from INR to selected currency
    return amountInINR * (_exchangeRates[_selectedCurrency] ?? 1);
  }

  String formatAmount(double amount, {String? fromCurrency}) {
    final convertedAmount = convertAmount(amount, fromCurrency: fromCurrency);
    return '${currencySymbols[_selectedCurrency] ?? _selectedCurrency} ${convertedAmount.toStringAsFixed(2)}';
  }
}
