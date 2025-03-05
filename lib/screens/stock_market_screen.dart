import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/stock_provider.dart';
import '../models/stock.dart';
import 'package:url_launcher/url_launcher.dart';
import './stock_detail_screen.dart';

class StockMarketScreen extends StatefulWidget {
  const StockMarketScreen({super.key});

  @override
  _StockMarketScreenState createState() => _StockMarketScreenState();
}

class _StockMarketScreenState extends State<StockMarketScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _searchStocks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    final results = await Provider.of<StockProvider>(context, listen: false)
        .searchStocks(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $url'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Market',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Watchlist'),
            Tab(text: 'Market News'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final stockProvider = Provider.of<StockProvider>(context, listen: false);
              if (_tabController.index == 0) {
                stockProvider.refreshWatchlist();
              } else {
                stockProvider.refreshMarketNews();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWatchlistTab(),
          _buildMarketNewsTab(),
        ],
      ),
    );
  }

  Widget _buildWatchlistTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stocks (e.g., AAPL, MSFT)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              _searchStocks(value);
            },
          ),
        ),
        if (_isSearching)
          const Center(child: CircularProgressIndicator())
        else if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  title: Text(result['symbol'] ?? ''),
                  subtitle: Text(
                    result['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      Provider.of<StockProvider>(context, listen: false)
                          .addToWatchlist(result['symbol'] ?? '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added ${result['symbol']} to watchlist'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Clear search results after adding
                      setState(() {
                        _searchResults = [];
                        _searchController.clear();
                      });
                    },
                    tooltip: 'Add to watchlist',
                  ),
                  onTap: () {
                    Provider.of<StockProvider>(context, listen: false)
                        .addToWatchlist(result['symbol'] ?? '');
                    // Clear search results after adding
                    setState(() {
                      _searchResults = [];
                      _searchController.clear();
                    });
                  },
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No results found'),
          )
        else
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, stockProvider, child) {
                if (stockProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (stockProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading stocks',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(stockProvider.error ?? ''),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              stockProvider.refreshWatchlist();
                            },
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final watchlist = stockProvider.watchlist;
                
                if (watchlist.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.show_chart,
                            color: Colors.grey,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your watchlist is empty',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Search for stocks above and add them to your watchlist',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => stockProvider.refreshWatchlist(),
                  child: ListView.builder(
                    itemCount: watchlist.length,
                    itemBuilder: (context, index) {
                      final stock = watchlist[index];
                      return _buildStockCard(context, stock);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMarketNewsTab() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, child) {
        if (stockProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (stockProvider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading market news',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(stockProvider.error ?? ''),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      stockProvider.refreshMarketNews();
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }
        
        final news = stockProvider.marketNews;
        
        if (news.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.newspaper,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No market news available',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      stockProvider.refreshMarketNews();
                    },
                    child: const Text('Refresh News'),
                  ),
                ],
              ),
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => stockProvider.refreshMarketNews(),
          child: ListView.builder(
            itemCount: news.length,
            itemBuilder: (context, index) {
              final article = news[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    _launchUrl(article.url);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.imageUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Image.network(
                            article.imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              article.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  article.source,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDateTime(article.publishedAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStockCard(BuildContext context, Stock stock) {
    final isPositive = stock.change >= 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StockDetailScreen(stock: stock),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                        stock.symbol,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        stock.name,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.show_chart),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StockDetailScreen(stock: stock),
                            ),
                          );
                        },
                        tooltip: 'View chart',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          Provider.of<StockProvider>(context, listen: false)
                              .removeFromWatchlist(stock.symbol);
                        },
                        tooltip: 'Remove from watchlist',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${stock.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${stock.change.toStringAsFixed(2)} (${stock.changePercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStockDetail('Open', '\$${stock.open.toStringAsFixed(2)}'),
                  _buildStockDetail('High', '\$${stock.high.toStringAsFixed(2)}'),
                  _buildStockDetail('Low', '\$${stock.low.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
