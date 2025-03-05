import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction.dart';
import '../providers/currency_provider.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyARiGMhrYFP4ebAPhTAamHgc5TVUUkrB7M';
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
      final recurringTotal = recurringExpenses.fold(0.0, (sum, tx) => sum + tx.amount);

      // Format for prompt
      final categorySpendingText = categorySpending.entries
          .map((e) => '- ${e.key}: ${currencyProvider.formatAmount(e.value)}')
          .join('\n');

      final recurringText = recurringExpenses
          .map((tx) => '- ${tx.title}: ${currencyProvider.formatAmount(tx.amount)} (${tx.recurringFrequency})')
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
      // Create category spending map from transactions
      final Map<String, double> categorySpending = {};
      for (var transaction in transactions) {
        final category = transaction.category;
        final amount = transaction.amount;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }

      // Format category spending for prompt
      final categorySpendingText = categorySpending.entries
          .map((e) => '- ${e.key}: ${currencyProvider.formatAmount(e.value)}')
          .join('\n');

      // Create prompt based on financial data
      String prompt = '''
You are a financial advisor AI. Based on the following financial information, provide personalized financial advice:

Monthly Income: ${currencyProvider.formatAmount(income)}
Monthly Budget: ${currencyProvider.formatAmount(budget)}
Total Monthly Expenses: ${currencyProvider.formatAmount(expenses)}
Remaining Budget: ${currencyProvider.formatAmount(budget - expenses)}
Overall Balance: ${currencyProvider.formatAmount(income - expenses)}

Recent Transactions by Category:
$categorySpendingText

${specificQuestion != null ? 'The user has a specific question: $specificQuestion' : 'Provide general financial advice based on the spending patterns and suggest ways to improve financial health.'}

Please provide actionable advice that is specific to this financial situation. Include suggestions for budgeting, saving, and potential areas to reduce spending if necessary.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'Unable to generate financial advice at this time.';
    } catch (e) {
      return 'Error generating financial advice: ${e.toString()}';
    }
  }
}
