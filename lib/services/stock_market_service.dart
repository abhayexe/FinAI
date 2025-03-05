import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/stock.dart';
import '../models/market_news.dart';

class StockMarketService {
  // API key from .env file
  static String? get apiKey => dotenv.env['STOCK_API_KEY'];
  
  // Base URL for Alpha Vantage API
  static const String baseUrl = 'https://www.alphavantage.co/query';
  
  // Get stock quote for a symbol
  static Future<Stock> getStockQuote(String symbol) async {
    if (apiKey == null) {
      throw Exception('API key not found. Add STOCK_API_KEY to your .env file');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$apiKey'),
      );
      
      print('Stock API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Stock API Response Data: ${data.keys}');
        
        if (data.containsKey('Note')) {
          print('API Limit Reached: ${data['Note']}');
          // Return mock data for the requested symbol
          return _getMockStockData(symbol);
        }
        
        if (data.containsKey('Error Message')) {
          print('API Error: ${data['Error Message']}');
          return _getMockStockData(symbol);
        }
        
        if (!data.containsKey('Global Quote') || data['Global Quote'] == null || (data['Global Quote'] as Map).isEmpty) {
          print('No stock data found in response');
          return _getMockStockData(symbol);
        }
        
        final quote = data['Global Quote'] as Map<String, dynamic>;
        
        return Stock(
          symbol: symbol,
          name: _getCompanyNameForSymbol(symbol),
          price: double.parse(quote['05. price'] ?? '0'),
          change: double.parse(quote['09. change'] ?? '0'),
          changePercent: double.parse((quote['10. change percent'] ?? '0%').replaceAll('%', '')),
          open: double.parse(quote['02. open'] ?? '0'),
          high: double.parse(quote['03. high'] ?? '0'),
          low: double.parse(quote['04. low'] ?? '0'),
          volume: int.parse(quote['06. volume'] ?? '0'),
        );
      } else {
        print('Stock API Error: ${response.statusCode} - ${response.body}');
        return _getMockStockData(symbol);
      }
    } catch (e) {
      print('Exception in getStockQuote: $e');
      return _getMockStockData(symbol);
    }
  }
  
  // Get historical stock data for a symbol
  static Future<List<Map<String, dynamic>>> getHistoricalData(String symbol, {String interval = 'daily'}) async {
    if (apiKey == null) {
      throw Exception('API key not found. Add STOCK_API_KEY to your .env file');
    }
    
    try {
      final function = interval == 'daily' ? 'TIME_SERIES_DAILY' : 'TIME_SERIES_INTRADAY';
      final intervalParam = interval == 'daily' ? '' : '&interval=60min';
      
      final response = await http.get(
        Uri.parse('$baseUrl?function=$function$intervalParam&symbol=$symbol&apikey=$apiKey&outputsize=compact'),
      );
      
      print('Historical Data API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Historical Data API Response Keys: ${data.keys}');
        
        if (data.containsKey('Note')) {
          print('API Limit Reached: ${data['Note']}');
          return _getMockHistoricalData(symbol);
        }
        
        if (data.containsKey('Error Message')) {
          print('API Error: ${data['Error Message']}');
          return _getMockHistoricalData(symbol);
        }
        
        final timeSeriesKey = interval == 'daily' ? 'Time Series (Daily)' : 'Time Series (60min)';
        
        if (!data.containsKey(timeSeriesKey)) {
          print('No historical data found in response');
          return _getMockHistoricalData(symbol);
        }
        
        final timeSeries = data[timeSeriesKey] as Map<String, dynamic>;
        final result = <Map<String, dynamic>>[];
        
        timeSeries.forEach((date, values) {
          result.add({
            'date': date,
            'open': double.parse(values['1. open'] ?? '0'),
            'high': double.parse(values['2. high'] ?? '0'),
            'low': double.parse(values['3. low'] ?? '0'),
            'close': double.parse(values['4. close'] ?? '0'),
            'volume': int.parse(values['5. volume'] ?? '0'),
          });
        });
        
        // Sort by date (newest first)
        result.sort((a, b) => b['date'].compareTo(a['date']));
        
        return result;
      } else {
        print('Historical Data API Error: ${response.statusCode} - ${response.body}');
        return _getMockHistoricalData(symbol);
      }
    } catch (e) {
      print('Exception in getHistoricalData: $e');
      return _getMockHistoricalData(symbol);
    }
  }
  
  // Helper to get company name for a symbol
  static String _getCompanyNameForSymbol(String symbol) {
    final companies = {
      'AAPL': 'Apple Inc.',
      'MSFT': 'Microsoft Corporation',
      'GOOGL': 'Alphabet Inc.',
      'AMZN': 'Amazon.com Inc.',
      'META': 'Meta Platforms Inc.',
      'TSLA': 'Tesla Inc.',
      'NVDA': 'NVIDIA Corporation',
      'JPM': 'JPMorgan Chase & Co.',
      'NFLX': 'Netflix Inc.',
      'DIS': 'The Walt Disney Company',
      'INTC': 'Intel Corporation',
      'AMD': 'Advanced Micro Devices Inc.',
      'BA': 'Boeing Company',
      'KO': 'Coca-Cola Company',
      'PEP': 'PepsiCo Inc.',
      'WMT': 'Walmart Inc.',
      'TGT': 'Target Corporation',
      'SBUX': 'Starbucks Corporation',
      'NKE': 'Nike Inc.',
      'ADBE': 'Adobe Inc.',
    };
    
    return companies[symbol.toUpperCase()] ?? 'Unknown Company';
  }
  
  // Mock stock data for testing
  static Stock _getMockStockData(String symbol) {
    final random = Random();
    final basePrice = {
      'AAPL': 175.0,
      'MSFT': 350.0,
      'GOOGL': 140.0,
      'AMZN': 175.0,
      'META': 480.0,
      'TSLA': 180.0,
      'NVDA': 850.0,
      'JPM': 190.0,
      'NFLX': 600.0,
      'DIS': 110.0,
    }[symbol.toUpperCase()] ?? 100.0;
    
    final price = basePrice + random.nextDouble() * 10 - 5;
    final change = random.nextDouble() * 6 - 3; // Between -3 and +3
    final changePercent = (change / price) * 100;
    
    return Stock(
      symbol: symbol.toUpperCase(),
      name: _getCompanyNameForSymbol(symbol.toUpperCase()),
      price: price,
      change: change,
      changePercent: changePercent,
      open: price - random.nextDouble() * 2,
      high: price + random.nextDouble() * 3,
      low: price - random.nextDouble() * 3,
      volume: 1000000 + random.nextInt(9000000),
    );
  }
  
  // Mock historical data for testing
  static List<Map<String, dynamic>> _getMockHistoricalData(String symbol) {
    final random = Random();
    final result = <Map<String, dynamic>>[];
    final basePrice = {
      'AAPL': 175.0,
      'MSFT': 350.0,
      'GOOGL': 140.0,
      'AMZN': 175.0,
      'META': 480.0,
      'TSLA': 180.0,
      'NVDA': 850.0,
      'JPM': 190.0,
      'NFLX': 600.0,
      'DIS': 110.0,
    }[symbol.toUpperCase()] ?? 100.0;
    
    double lastClose = basePrice;
    
    // Generate 365 days of data for a full year
    for (int i = 0; i < 365; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      // Create more realistic price movements
      // Add some weekly patterns and monthly trends
      double trend = 0;
      
      // Weekly pattern (weekends might have more movement)
      if (date.weekday == DateTime.friday || date.weekday == DateTime.monday) {
        trend += (random.nextDouble() * 2 - 1) * 2; // More volatility on Mon/Fri
      }
      
      // Monthly trend
      if (date.day < 10) {
        trend += 0.2; // Slight upward trend at start of month
      } else if (date.day > 20) {
        trend -= 0.1; // Slight downward trend at end of month
      }
      
      // Quarterly effects (earnings seasons)
      if ((date.month == 1 || date.month == 4 || date.month == 7 || date.month == 10) && 
          date.day >= 15 && date.day <= 25) {
        trend += (random.nextDouble() * 6 - 3); // Higher volatility during earnings season
      }
      
      // Market corrections every few months
      if (i % 90 == 0) {
        trend -= random.nextDouble() * 5; // Occasional dips
      }
      
      // General market uptrend over time
      trend += 0.05;
      
      // Calculate the daily change with the trend factor
      final change = (random.nextDouble() * 3 - 1.5) + trend;
      
      // Ensure we don't go negative
      final close = max(lastClose + change, 1.0);
      final open = max(close - random.nextDouble() * 2 + 1, 1.0);
      final high = max(max(open, close) + random.nextDouble() * 1.5, 1.0);
      final low = max(min(open, close) - random.nextDouble() * 1.5, 0.5);
      
      // Volume tends to be higher on volatile days
      final volumeBase = 1000000 + random.nextInt(5000000);
      final volumeMultiplier = 1.0 + (change.abs() / basePrice) * 20;
      final volume = (volumeBase * volumeMultiplier).toInt();
      
      result.add({
        'date': dateStr,
        'open': double.parse(open.toStringAsFixed(2)),
        'high': double.parse(high.toStringAsFixed(2)),
        'low': double.parse(low.toStringAsFixed(2)),
        'close': double.parse(close.toStringAsFixed(2)),
        'volume': volume,
      });
      
      lastClose = close;
    }
    
    return result;
  }
  
  // Get market news
  static Future<List<MarketNews>> getMarketNews({int limit = 10}) async {
    if (apiKey == null) {
      throw Exception('API key not found. Add STOCK_API_KEY to your .env file');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?function=NEWS_SENTIMENT&apikey=$apiKey&tickers=AAPL,MSFT,GOOGL&sort=LATEST'),
      );
      
      print('News API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('News API Response Data: ${data.keys}');
        
        if (data.containsKey('Note')) {
          print('API Limit Reached: ${data['Note']}');
          throw Exception('API call frequency limit reached. Please try again later.');
        }
        
        if (data.containsKey('Error Message')) {
          print('API Error: ${data['Error Message']}');
          throw Exception(data['Error Message']);
        }
        
        if (!data.containsKey('feed') || data['feed'] == null) {
          print('No news feed found in response');
          // Return mock data for testing when no real data is available
          return _getMockNewsData();
        }
        
        final feed = data['feed'] as List;
        print('News feed items count: ${feed.length}');
        
        if (feed.isEmpty) {
          print('News feed is empty');
          return _getMockNewsData();
        }
        
        final news = <MarketNews>[];
        
        for (var i = 0; i < feed.length && i < limit; i++) {
          final item = feed[i];
          
          try {
            news.add(
              MarketNews(
                title: item['title'] ?? 'No Title',
                url: item['url'] ?? '',
                description: item['summary'] ?? 'No description available',
                source: item['source'] ?? 'Unknown Source',
                imageUrl: item['banner_image'] ?? '',
                publishedAt: DateTime.tryParse(item['time_published'] ?? '') ?? DateTime.now(),
              ),
            );
          } catch (e) {
            print('Error parsing news item: $e');
            print('News item data: $item');
          }
        }
        
        print('Parsed news items: ${news.length}');
        return news;
      } else {
        print('News API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load market news: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getMarketNews: $e');
      // Return mock data when there's an error
      return _getMockNewsData();
    }
  }
  
  // Mock news data for testing
  static List<MarketNews> _getMockNewsData() {
    return [
      MarketNews(
        title: 'Apple Announces New iPhone Model',
        url: 'https://example.com/apple-news',
        description: 'Apple Inc. has unveiled its latest iPhone model with groundbreaking features including enhanced AI capabilities and improved battery life.',
        source: 'Tech News',
        imageUrl: 'https://images.unsplash.com/photo-1570222094114-d054a817e56b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MarketNews(
        title: 'Microsoft Reports Strong Q1 Earnings',
        url: 'https://example.com/microsoft-earnings',
        description: 'Microsoft Corporation exceeded analyst expectations with its Q1 earnings report, showing significant growth in cloud services and AI solutions.',
        source: 'Financial Times',
        imageUrl: 'https://images.unsplash.com/photo-1633419461186-7d40a38105ec?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      MarketNews(
        title: 'Google Unveils New AI Research Breakthrough',
        url: 'https://example.com/google-ai',
        description: 'Google researchers have announced a significant breakthrough in artificial intelligence that could revolutionize natural language processing and machine learning applications.',
        source: 'AI Today',
        imageUrl: 'https://images.unsplash.com/photo-1573804633927-bfcbcd909acd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      MarketNews(
        title: 'Tesla Expands Production Capacity',
        url: 'https://example.com/tesla-expansion',
        description: 'Tesla Inc. has announced plans to expand its production capacity with new factories in Asia and Europe to meet growing demand for electric vehicles.',
        source: 'Auto News',
        imageUrl: 'https://images.unsplash.com/photo-1617704548623-340376564e68?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      MarketNews(
        title: 'Amazon Acquires AI Startup',
        url: 'https://example.com/amazon-acquisition',
        description: 'Amazon has acquired a promising AI startup specializing in retail automation technology to enhance its e-commerce platform and logistics operations.',
        source: 'Business Insider',
        imageUrl: 'https://images.unsplash.com/photo-1523474253046-8cd2748b5fd2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        publishedAt: DateTime.now().subtract(const Duration(hours: 18)),
      ),
    ];
  }
  
  // Search for stocks
  static Future<List<Map<String, String>>> searchStocks(String query) async {
    if (apiKey == null) {
      throw Exception('API key not found. Add STOCK_API_KEY to your .env file');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl?function=SYMBOL_SEARCH&keywords=$query&apikey=$apiKey'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data.containsKey('Note')) {
        throw Exception('API call frequency limit reached. Please try again later.');
      }
      
      if (data.containsKey('Error Message')) {
        throw Exception(data['Error Message']);
      }
      
      if (data.containsKey('bestMatches')) {
        final matches = data['bestMatches'] as List;
        
        return matches.map<Map<String, String>>((match) {
          return {
            'symbol': match['1. symbol'] ?? '',
            'description': match['2. name'] ?? '',
            'type': match['3. type'] ?? '',
            'region': match['4. region'] ?? '',
          };
        }).toList();
      }
      
      return [];
    } else {
      throw Exception('Failed to search stocks: ${response.statusCode}');
    }
  }
}
