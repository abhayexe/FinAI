import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/subscription_screen.dart';

class PredictionData {
  final String title;
  final String description;
  final double currentValue;
  final double predictedValue;
  final IconData icon;

  PredictionData({
    required this.title,
    required this.description,
    required this.currentValue,
    required this.predictedValue,
    required this.icon,
  });
}

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  _AIPredictionsScreenState createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  String _rawPredictions = '';
  List<PredictionData> _predictions = [];
  bool _isLoading = false;
  String _error = '';
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    _loadPredictions();
    
    // Check subscription status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionProvider>(context, listen: false).checkSubscription();
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _parsePredictions(String rawPredictions) {
    // This is a simplified example. In reality, you'd parse the AI response more carefully
    _predictions = [
      PredictionData(
        title: 'Monthly Savings',
        description: 'Expected savings trend based on current spending patterns',
        currentValue: 500,
        predictedValue: 750,
        icon: Icons.savings,
      ),
      PredictionData(
        title: 'Expenses',
        description: 'Projected expenses for next month',
        currentValue: 1200,
        predictedValue: 1100,
        icon: Icons.trending_down,
      ),
      PredictionData(
        title: 'Income',
        description: 'Projected income for next month',
        currentValue: 2000,
        predictedValue: 2200,
        icon: Icons.trending_up,
      ),
    ];
  }

  Future<void> _loadPredictions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final predictions = await financeProvider.getFinancialPredictions(currencyProvider);
      
      if (!mounted) return;
      setState(() {
        _rawPredictions = predictions;
        _parsePredictions(predictions);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load predictions: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildFormattedText(String text) {
    // Process the text to convert markdown to styled text
    final List<Map<String, dynamic>> segments = [];
    
    // Process bold text (text between ** **)
    RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;
    
    // Find all bold segments
    for (Match match in boldRegex.allMatches(text)) {
      // Add normal text before this bold segment
      if (match.start > lastEnd) {
        segments.add({
          'text': text.substring(lastEnd, match.start),
          'isBold': false
        });
      }
      
      // Add the bold text (without the ** markers)
      segments.add({
        'text': match.group(1)!,
        'isBold': true
      });
      
      lastEnd = match.end;
    }
    
    // Add any remaining text after the last bold segment
    if (lastEnd < text.length) {
      segments.add({
        'text': text.substring(lastEnd),
        'isBold': false
      });
    }
    
    // Clean up the segments
    for (var i = 0; i < segments.length; i++) {
      String segmentText = segments[i]['text'];
      
      // Remove markdown symbols
      segmentText = segmentText.replaceAll('#', '');
      
      // Process bullet points
      final lines = segmentText.split('\n');
      final cleanedLines = lines.map((line) {
        // Remove bullet points with numbers (e.g., "1. ")
        line = line.replaceAll(RegExp(r'^\d+\.\s*'), '');
        // Remove markdown bullet points
        line = line.replaceAll(RegExp(r'^\s*[-*]\s*'), '• ');
        return line.trim();
      }).where((line) => line.isNotEmpty).toList();
      
      segments[i]['text'] = cleanedLines.join('\n');
    }
    
    // Build RichText with TextSpans for formatting
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
        children: segments.map((segment) {
          return TextSpan(
            text: segment['text'],
            style: TextStyle(
              fontWeight: segment['isBold'] ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPredictionCard(PredictionData prediction, CurrencyProvider currencyProvider) {
    final percentChange = ((prediction.predictedValue - prediction.currentValue) / prediction.currentValue * 100).abs();
    final isIncrease = prediction.predictedValue > prediction.currentValue;
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Icon(prediction.icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        prediction.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: 6,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 2),
                        const FlSpot(2, 4),
                        const FlSpot(3, 3),
                        const FlSpot(4, 5),
                      ],
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      currencyProvider.formatAmount(prediction.currentValue),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isIncrease ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isIncrease ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentChange.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isIncrease ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Predicted',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      currencyProvider.formatAmount(prediction.predictedValue),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final hasSubscription = subscriptionProvider.hasSubscription;
    final hasAdvancedAI = subscriptionProvider.hasAdvancedAI;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Predictions', style: GoogleFonts.poppins()),
        actions: [
          if (hasSubscription)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Chip(
                backgroundColor: Colors.amber.shade700,
                label: Text(
                  'PREMIUM',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                avatar: Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: GoogleFonts.poppins(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadPredictions,
                        child: Text('Retry', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasSubscription && hasAdvancedAI)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Using advanced AI model for premium subscribers',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!hasSubscription)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Upgrade to Premium',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Get access to our advanced AI model for more accurate predictions and personalized financial advice.',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const SubscriptionScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Learn More',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        'Financial Insights',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI-powered predictions based on your spending patterns',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._predictions.map((prediction) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPredictionCard(prediction, currencyProvider),
                          )),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Detailed Analysis',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFormattedText(_rawPredictions),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPredictions,
        backgroundColor: Theme.of(context).colorScheme.primary,
        tooltip: 'Refresh Predictions',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
