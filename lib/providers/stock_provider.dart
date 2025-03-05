import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock.dart';
import '../models/market_news.dart';
import '../services/stock_market_service.dart';

class StockProvider with ChangeNotifier {
  List<Stock> _watchlist = [];
  List<MarketNews> _marketNews = [];
  final Map<String, List<Map<String, dynamic>>> _historicalData = {};
  bool _isLoading = false;
  String? _error;

  List<Stock> get watchlist => [..._watchlist];
  List<MarketNews> get marketNews => [..._marketNews];
  Map<String, List<Map<String, dynamic>>> get historicalData => {..._historicalData};
  bool get isLoading => _isLoading;
  String? get error => _error;

  StockProvider() {
    _loadWatchlist();
    refreshMarketNews();
  }

  Future<void> _loadWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchlistJson = prefs.getStringList('stock_watchlist') ?? [];
      
      if (watchlistJson.isEmpty) {
        // Add some default stocks if watchlist is empty
        await addToWatchlist('AAPL');
        await addToWatchlist('MSFT');
        return;
      }
      
      _watchlist = watchlistJson
          .map((json) => Stock.fromJson(jsonDecode(json)))
          .toList();
      
      // Refresh stock data
      refreshWatchlist();
    } catch (e) {
      print('Error loading watchlist: $e');
      _error = 'Failed to load watchlist: $e';
      notifyListeners();
    }
  }

  Future<void> _saveWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final watchlistJson = _watchlist
          .map((stock) => jsonEncode(stock.toJson()))
          .toList();
      
      await prefs.setStringList('stock_watchlist', watchlistJson);
    } catch (e) {
      print('Error saving watchlist: $e');
    }
  }

  Future<void> refreshWatchlist() async {
    if (_watchlist.isEmpty) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedWatchlist = <Stock>[];
      
      for (final stock in _watchlist) {
        final updatedStock = await StockMarketService.getStockQuote(stock.symbol);
        updatedWatchlist.add(updatedStock);
        
        // Also fetch historical data for each stock
        await getHistoricalData(stock.symbol);
      }
      
      _watchlist = updatedWatchlist;
      _saveWatchlist();
    } catch (e) {
      _error = 'Failed to refresh watchlist: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToWatchlist(String symbol) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Check if stock is already in watchlist
      if (_watchlist.any((stock) => stock.symbol.toUpperCase() == symbol.toUpperCase())) {
        _error = 'Stock is already in your watchlist';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      final stock = await StockMarketService.getStockQuote(symbol);
      _watchlist.add(stock);
      
      // Also fetch historical data for the new stock
      await getHistoricalData(symbol);
      
      await _saveWatchlist();
    } catch (e) {
      _error = 'Failed to add stock: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void removeFromWatchlist(String symbol) {
    _watchlist.removeWhere((stock) => stock.symbol.toUpperCase() == symbol.toUpperCase());
    // Also remove historical data
    _historicalData.remove(symbol.toUpperCase());
    _saveWatchlist();
    notifyListeners();
  }

  Future<void> refreshMarketNews() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      _marketNews = await StockMarketService.getMarketNews();
    } catch (e) {
      _error = 'Failed to load market news: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricalData(String symbol, {bool refresh = false}) async {
    final upperSymbol = symbol.toUpperCase();
    
    // Return cached data if available and not refreshing
    if (!refresh && _historicalData.containsKey(upperSymbol)) {
      return _historicalData[upperSymbol]!;
    }
    
    try {
      final data = await StockMarketService.getHistoricalData(upperSymbol);
      _historicalData[upperSymbol] = data;
      notifyListeners();
      return data;
    } catch (e) {
      print('Error fetching historical data: $e');
      // Return empty list if there's an error
      return [];
    }
  }

  Future<List<Map<String, String>>> searchStocks(String query) async {
    if (query.isEmpty) return [];
    
    try {
      return await StockMarketService.searchStocks(query);
    } catch (e) {
      _error = 'Failed to search stocks: $e';
      return [];
    }
  }
}
