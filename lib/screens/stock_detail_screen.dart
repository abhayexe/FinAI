import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/stock_provider.dart';
import '../models/stock.dart';
import '../widgets/stock_chart.dart';

class StockDetailScreen extends StatefulWidget {
  final Stock stock;
  
  const StockDetailScreen({
    super.key,
    required this.stock,
  });

  @override
  _StockDetailScreenState createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }
  
  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<StockProvider>(context, listen: false)
          .getHistoricalData(widget.stock.symbol, refresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load historical data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final stockProvider = Provider.of<StockProvider>(context);
    final historicalData = stockProvider.historicalData[widget.stock.symbol.toUpperCase()] ?? [];
    final isPositive = widget.stock.change >= 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stock.symbol,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoricalData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.stock.name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$${widget.stock.price.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isPositive ? Colors.green : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? '+' : ''}${widget.stock.change.toStringAsFixed(2)} (${widget.stock.changePercent.toStringAsFixed(2)}%)',
                                    style: TextStyle(
                                      color: isPositive ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (historicalData.isNotEmpty)
                    StockChart(
                      historicalData: historicalData,
                      symbol: widget.stock.symbol,
                      lineColor: isPositive ? Colors.green : Colors.red,
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.show_chart,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No historical data available',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This could be due to API limits or the data is not available for this stock.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadHistoricalData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Key Statistics',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildKeyStatistics(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'About ${widget.stock.name}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _getCompanyDescription(widget.stock.symbol),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
  
  Widget _buildKeyStatistics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Open', '\$${widget.stock.open.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildStatItem('High', '\$${widget.stock.high.toStringAsFixed(2)}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Low', '\$${widget.stock.low.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildStatItem('Volume', _formatVolume(widget.stock.volume)),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(2)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(2)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(2)}K';
    } else {
      return volume.toString();
    }
  }
  
  String _getCompanyDescription(String symbol) {
    final descriptions = {
      'AAPL': 'Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide. The company offers iPhone, a line of smartphones; Mac, a line of personal computers; iPad, a line of multi-purpose tablets; and wearables, home, and accessories comprising AirPods, Apple TV, Apple Watch, Beats products, and HomePod.',
      'MSFT': 'Microsoft Corporation develops, licenses, and supports software, services, devices, and solutions worldwide. The company operates in three segments: Productivity and Business Processes, Intelligent Cloud, and More Personal Computing. The company offers Office, Exchange, SharePoint, Microsoft Teams, Office 365 Security and Compliance, Microsoft Viva, and Microsoft 365 Copilot.',
      'GOOGL': 'Alphabet Inc. offers various products and platforms in the United States, Europe, the Middle East, Africa, the Asia-Pacific, Canada, and Latin America. It operates through Google Services, Google Cloud, and Other Bets segments. The Google Services segment provides products and services, including ads, Android, Chrome, hardware, Gmail, Google Drive, Google Maps, Google Photos, Google Play, Search, and YouTube.',
      'AMZN': 'Amazon.com, Inc. engages in the retail sale of consumer products and subscriptions through online and physical stores in North America and internationally. It operates through three segments: North America, International, and Amazon Web Services (AWS). The company\'s products offered through its stores include merchandise and content purchased for resale; and products offered by third-party sellers.',
      'META': 'Meta Platforms, Inc. engages in the development of products that enable people to connect and share with friends and family through mobile devices, personal computers, virtual reality headsets, and wearables worldwide. It operates in two segments, Family of Apps and Reality Labs.',
      'TSLA': 'Tesla, Inc. designs, develops, manufactures, leases, and sells electric vehicles, and energy generation and storage systems in the United States, China, and internationally. It operates in two segments, Automotive, and Energy Generation and Storage. The Automotive segment offers electric vehicles, as well as sells automotive regulatory credits; and non-warranty after-sales vehicle, used vehicles, body shop and parts, supercharging, retail merchandise, and vehicle insurance services.',
      'NVDA': 'NVIDIA Corporation provides graphics, and compute and networking solutions in the United States, Taiwan, China, and internationally. The company\'s Graphics segment offers GeForce GPUs for gaming and PCs, the GeForce NOW game streaming service and related infrastructure, and solutions for gaming platforms; Quadro/NVIDIA RTX GPUs for enterprise workstation graphics; vGPU software for cloud-based visual and virtual computing; automotive platforms for infotainment systems.',
    };
    
    return descriptions[symbol.toUpperCase()] ?? 
        'A publicly traded company listed on the stock exchange. The company operates in various sectors and markets, providing products and services to customers worldwide.';
  }
}
