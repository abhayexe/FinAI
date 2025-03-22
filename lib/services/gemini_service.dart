import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ??
        'AIzaSyARiGMhrYFP4ebAPhTAamHgc5TVUUkrB7M';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> getFinancialPredictions({
    required List<Transaction> transactions,
    required List<Transaction> recurringExpenses,
    required double totalBalance,
    required double monthlyIncome,
    required CurrencyProvider currencyProvider,
  }) async {
    try {
      // Create category spending map
      final Map<String, double> categorySpending = {};
      for (var transaction in transactions) {
        final category = transaction.category;
        final amount = transaction.amount;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }

      // Calculate recurring total
      final recurringTotal =
          recurringExpenses.fold(0.0, (sum, tx) => sum + tx.amount);

      // Format for prompt
      final categorySpendingText = categorySpending.entries
          .map((e) => '- ${e.key}: ${currencyProvider.formatAmount(e.value)}')
          .join('\n');

      final recurringText = recurringExpenses
          .map((tx) =>
              '- ${tx.title}: ${currencyProvider.formatAmount(tx.amount)} (${tx.recurringFrequency})')
          .join('\n');

      String prompt = '''
You are a financial analysis AI. Based on this financial data, provide detailed predictions and analysis:

Monthly Income: ${currencyProvider.formatAmount(monthlyIncome)}
Current Balance: ${currencyProvider.formatAmount(totalBalance)}
Total Monthly Recurring Expenses: ${currencyProvider.formatAmount(recurringTotal)}

Recent Spending by Category:
$categorySpendingText

Monthly Recurring Expenses:
$recurringText

Please analyze this data and provide:
1. Spending Pattern Analysis
2. Next Month's Predictions
3. Budget Recommendations
4. Financial Health Score (0-100)
5. Money-Saving Opportunities

Format the response in a clear, structured way with bullet points.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'Unable to generate predictions at this time.';
    } catch (e) {
      return 'Error generating predictions: ${e.toString()}';
    }
  }

  Future<String> getFinancialAdvice({
    required double income,
    required double expenses,
    required double budget,
    required List<Transaction> transactions,
    required CurrencyProvider currencyProvider,
    String? specificQuestion,
  }) async {
    try {
      String prompt = specificQuestion ?? '''
      As a financial advisor, please analyze my financial data and provide advice:

      Monthly Income: ${currencyProvider.formatAmount(income)}
      Monthly Budget: ${currencyProvider.formatAmount(budget)}
      Total Expenses: ${currencyProvider.formatAmount(expenses)}

      ${transactions.isNotEmpty ? 'Recent Transactions:' : 'No recent transactions available.'}
      ''';

      if (transactions.isNotEmpty) {
        // Add transactions info to the prompt
        // Group transactions by category
        Map<String, List<Transaction>> transactionsByCategory = {};
        for (var tx in transactions) {
          if (!transactionsByCategory.containsKey(tx.category)) {
            transactionsByCategory[tx.category] = [];
          }
          transactionsByCategory[tx.category]!.add(tx);
        }

        // Calculate and add total amounts per category
        transactionsByCategory.forEach((category, txList) {
          final totalAmount = txList.fold<double>(
              0, (sum, tx) => sum + (tx.isIncome ? -tx.amount : tx.amount));
          prompt += '\n$category: ${currencyProvider.formatAmount(totalAmount)}';
        });
      }

      prompt += '''

      ${specificQuestion != null ? '' : 'Please provide:'}
      ${specificQuestion != null ? '' : '1. Analysis of my spending habits'}
      ${specificQuestion != null ? '' : '2. Specific suggestions to improve my financial situation'}
      ${specificQuestion != null ? '' : '3. Budget optimization recommendations'}
      ''';

      print('Gemini Prompt: $prompt');
      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? 'Error: Unable to get a response';
      print('Gemini Response: $responseText');
      
      return responseText;
    } catch (e) {
      print('Gemini API Error: $e');
      return 'There was an error getting financial advice: ${e.toString()}';
    }
  }
}
