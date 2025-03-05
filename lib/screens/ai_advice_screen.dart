import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/finance_provider.dart';
import '../providers/currency_provider.dart';

class AIAdviceScreen extends StatefulWidget {
  const AIAdviceScreen({super.key});

  @override
  _AIAdviceScreenState createState() => _AIAdviceScreenState();
}

class _AIAdviceScreenState extends State<AIAdviceScreen> {
  String _advice = '';
  bool _isLoading = false;
  final _questionController = TextEditingController();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _getInitialAdvice();
  }

  @override
  void dispose() {
    _mounted = false;
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _getInitialAdvice() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final financeData = Provider.of<FinanceProvider>(context, listen: false);
      final currencyData = Provider.of<CurrencyProvider>(context, listen: false);
      final advice = await financeData.getFinancialAdvice(
        currencyProvider: currencyData,
      );
      
      if (!mounted) return;
      
      setState(() {
        _advice = advice;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _advice = 'Failed to get AI advice. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getSpecificAdvice() async {
    if (_questionController.text.trim().isEmpty) return;
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final financeData = Provider.of<FinanceProvider>(context, listen: false);
      final currencyData = Provider.of<CurrencyProvider>(context, listen: false);
      final advice = await financeData.getFinancialAdvice(
        specificQuestion: _questionController.text.trim(),
        currencyProvider: currencyData,
      );
      
      if (!mounted) return;
      
      setState(() {
        _advice = advice;
        _isLoading = false;
      });
      
      _questionController.clear();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _advice = 'Failed to get AI advice. Please try again later.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Financial Advisor',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Ask a specific question',
                  hintText: 'E.g., How can I reduce my spending?',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _getSpecificAdvice,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _getSpecificAdvice(),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: _buildFormattedText(_advice),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getInitialAdvice,
        tooltip: 'Get new advice',
        child: Icon(Icons.refresh),
      ),
    );
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
        style: GoogleFonts.poppins(
          fontSize: 16,
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
}
