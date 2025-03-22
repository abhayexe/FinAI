import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/financial_goal.dart';
import '../services/gemini_service.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/finance_provider.dart';

class BudgetAdjustment {
  final double oldBudget;
  final double newBudget;
  final String explanation;
  final DateTime timestamp;
  bool wasShown;

  BudgetAdjustment({
    required this.oldBudget,
    required this.newBudget,
    required this.explanation,
    required this.timestamp,
    this.wasShown = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldBudget': oldBudget,
      'newBudget': newBudget,
      'explanation': explanation,
      'timestamp': timestamp.toIso8601String(),
      'wasShown': wasShown,
    };
  }

  factory BudgetAdjustment.fromJson(Map<String, dynamic> json) {
    return BudgetAdjustment(
      oldBudget: json['oldBudget'],
      newBudget: json['newBudget'],
      explanation: json['explanation'],
      timestamp: DateTime.parse(json['timestamp']),
      wasShown: json['wasShown'] ?? false,
    );
  }
}

class GoalsProvider with ChangeNotifier {
  final GeminiService _geminiService;
  List<FinancialGoal> _goals = [];
  bool _autoBudgetAdjustEnabled = false;
  DateTime? _lastAutoAdjustment;
  BudgetAdjustment? _lastBudgetAdjustment;

  GoalsProvider(this._geminiService) {
    _loadGoals();
    _loadSettings();
  }

  List<FinancialGoal> get goals => [..._goals];
  bool get isAutoBudgetAdjustEnabled => _autoBudgetAdjustEnabled;
  DateTime? get lastAutoAdjustment => _lastAutoAdjustment;

  // Get all active goals (not completed)
  List<FinancialGoal> get activeGoals =>
      _goals.where((goal) => !goal.isCompleted).toList();

  // Get completed goals
  List<FinancialGoal> get completedGoals =>
      _goals.where((goal) => goal.isCompleted).toList();

  // Get goal by ID
  FinancialGoal? getGoalById(String id) {
    try {
      return _goals.firstWhere((goal) => goal.id == id);
    } catch (e) {
      return null;
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Load goals
      final goalsJson = prefs.getString('financial_goals');
      if (goalsJson != null) {
        final decodedGoals = jsonDecode(goalsJson) as List<dynamic>;
        _goals = decodedGoals.map((e) => FinancialGoal.fromJson(e)).toList();
      }

      // Load auto-adjust setting
      _autoBudgetAdjustEnabled =
          prefs.getBool('auto_budget_adjust_enabled') ?? false;

      final lastAdjustStr = prefs.getString('last_auto_adjustment');
      if (lastAdjustStr != null) {
        _lastAutoAdjustment = DateTime.parse(lastAdjustStr);
      }

      final lastBudgetAdjustmentJson =
          prefs.getString('last_budget_adjustment');
      if (lastBudgetAdjustmentJson != null) {
        _lastBudgetAdjustment =
            BudgetAdjustment.fromJson(json.decode(lastBudgetAdjustmentJson));
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    notifyListeners();
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Save goals
      final goalsJson = jsonEncode(_goals.map((g) => g.toJson()).toList());
      await prefs.setString('financial_goals', goalsJson);

      // Save auto-adjust setting
      await prefs.setBool(
          'auto_budget_adjust_enabled', _autoBudgetAdjustEnabled);
      if (_lastAutoAdjustment != null) {
        await prefs.setString(
            'last_auto_adjustment', _lastAutoAdjustment!.toIso8601String());
      }
      if (_lastBudgetAdjustment != null) {
        await prefs.setString('last_budget_adjustment',
            json.encode(_lastBudgetAdjustment!.toJson()));
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // Set auto budget adjustment enabled/disabled
  Future<void> setAutoBudgetAdjustEnabled(
      bool enabled, BuildContext? context) async {
    _autoBudgetAdjustEnabled = enabled;
    notifyListeners();
    await _saveSettings();

    print('Auto-budget adjustment ${enabled ? 'enabled' : 'disabled'}');

    // Always trigger an immediate budget adjustment when enabled and context is provided
    if (enabled && context != null) {
      print(
          'Triggering immediate budget adjustment after enabling auto-adjust');
      if (_goals.isEmpty) {
        print('Cannot adjust budget: no financial goals found');
        // Show a snackbar to inform the user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Add at least one financial goal to enable automatic budget adjustment'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Force a budget adjustment
        await autoAdjustBudget(context);
      }
    }
  }

  // Auto adjust budget based on financial goals
  Future<void> autoAdjustBudget(BuildContext context) async {
    if (_goals.isEmpty) {
      print('No goals found, skipping budget adjustment');
      return;
    }

    print('Starting automatic budget adjustment based on goals');
    final financeProvider =
        Provider.of<FinanceProvider>(context, listen: false);
    final currencyProvider =
        Provider.of<CurrencyProvider>(context, listen: false);

    try {
      // Get current budget
      final currentBudget = financeProvider.budget;
      print('Current budget: $currentBudget');

      // Get AI suggestions
      print('Requesting AI suggestions for budget adjustment');
      final suggestions = await getGoalBasedBudgetSuggestions(
        financeProvider.income,
        currentBudget,
        context,
      );
      print('Received AI response for budget adjustment');

      // Extract budget recommendation from AI response
      final double recommendedBudget =
          _extractBudgetFromAiResponse(suggestions, currentBudget);
      print('Recommended budget: $recommendedBudget');

      // Update budget if a valid recommendation was extracted
      if (recommendedBudget > 0) {
        print('Updating budget from $currentBudget to $recommendedBudget');

        // First set the new budget
        financeProvider.updateBudget(recommendedBudget);

        // Store the adjustment for notification
        _lastBudgetAdjustment = BudgetAdjustment(
          oldBudget: currentBudget,
          newBudget: recommendedBudget,
          explanation: suggestions,
          timestamp: DateTime.now(),
        );

        // Save last adjustment time
        _lastAutoAdjustment = DateTime.now();

        // Save settings
        await _saveSettings();

        print('Budget successfully updated to $recommendedBudget');
        notifyListeners();
      } else {
        print('Invalid recommended budget: $recommendedBudget, not updating');
      }
    } catch (e) {
      // Handle errors
      print('Failed to adjust budget: $e');
    }
  }

  // Extract budget recommendation from AI response
  double _extractBudgetFromAiResponse(String aiResponse, double currentBudget) {
    try {
      // Enhanced pattern to catch more budget recommendation formats
      final RegExp budgetRegexp = RegExp(
          r'budget of \$?(\d+[,\.]?\d*)|budget to \$?(\d+[,\.]?\d*)|recommend(?:ed)? (?:a |new )?budget (?:of |to )?\$?(\d+[,\.]?\d*)|adjust(?:ing)? (?:the )?budget to \$?(\d+[,\.]?\d*)|(?:set|setting) (?:the )?budget (?:to |at )?\$?(\d+[,\.]?\d*)|new budget (?:of |at )?\$?(\d+[,\.]?\d*)',
          caseSensitive: false);

      final match = budgetRegexp.firstMatch(aiResponse);

      if (match != null) {
        // Extract the matched amount from any of the capture groups
        String? value;
        for (int i = 1; i <= match.groupCount; i++) {
          if (match.group(i) != null) {
            value = match.group(i);
            break;
          }
        }

        if (value != null) {
          // Clean the value and parse it
          final cleanValue = value.replaceAll(',', '');
          final parsedValue = double.tryParse(cleanValue);

          if (parsedValue != null) {
            print('Extracted budget value: $parsedValue from AI response');
            return parsedValue;
          }
        }
      }

      // If no matches or parsing failed, try to extract any numerical value prefixed with $
      final RegExp dollarRegexp = RegExp(r'\$(\d+[,\.]?\d*)');
      final dollarMatch = dollarRegexp.firstMatch(aiResponse);
      if (dollarMatch != null && dollarMatch.group(1) != null) {
        final cleanValue = dollarMatch.group(1)!.replaceAll(',', '');
        final parsedValue = double.tryParse(cleanValue);
        if (parsedValue != null) {
          print('Extracted dollar amount: $parsedValue from AI response');
          return parsedValue;
        }
      }

      // If we didn't find a specific amount, fallback to current budget
      print(
          'Could not extract budget from AI response, keeping current budget: $currentBudget');
      return currentBudget;
    } catch (e) {
      // Return current budget if extraction fails
      print('Error extracting budget from AI response: $e');
      return currentBudget;
    }
  }

  // Load goals from SharedPreferences
  Future<void> _loadGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = prefs.getString('financial_goals');

      if (goalsJson != null) {
        final List<dynamic> decodedGoals = jsonDecode(goalsJson);
        _goals =
            decodedGoals.map((item) => FinancialGoal.fromMap(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
  }

  // Save goals to SharedPreferences
  Future<void> _saveGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = jsonEncode(_goals.map((goal) => goal.toMap()).toList());
      await prefs.setString('financial_goals', goalsJson);
    } catch (e) {
      debugPrint('Error saving goals: $e');
    }
  }

  // Add a new goal
  Future<void> addGoal(FinancialGoal goal, [BuildContext? context]) async {
    _goals.add(goal);
    notifyListeners();
    await _saveGoals();

    // If auto-adjustment is enabled and context is provided, trigger adjustment
    if (_autoBudgetAdjustEnabled && context != null) {
      await autoAdjustBudget(context);
    }
  }

  // Update an existing goal
  Future<void> updateGoal(FinancialGoal updatedGoal,
      [BuildContext? context]) async {
    final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);
    if (index != -1) {
      _goals[index] = updatedGoal;
      notifyListeners();
      await _saveGoals();

      // If auto-adjustment is enabled and context is provided, trigger adjustment
      if (_autoBudgetAdjustEnabled && context != null) {
        await autoAdjustBudget(context);
      }
    }
  }

  // Delete a goal
  Future<void> deleteGoal(String id, [BuildContext? context]) async {
    _goals.removeWhere((goal) => goal.id == id);
    notifyListeners();
    await _saveGoals();

    // If auto-adjustment is enabled and context is provided, trigger adjustment
    if (_autoBudgetAdjustEnabled && context != null && activeGoals.isNotEmpty) {
      await autoAdjustBudget(context);
    }
  }

  // Update progress for a goal
  Future<void> updateGoalProgress(String id, double currentAmount,
      [BuildContext? context]) async {
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index != -1) {
      final goal = _goals[index];
      final updatedGoal = goal.copyWith(
        currentAmount: currentAmount,
        isCompleted: currentAmount >= goal.targetAmount,
      );
      _goals[index] = updatedGoal;
      notifyListeners();
      await _saveGoals();

      // If auto-adjustment is enabled and context is provided, trigger adjustment
      if (_autoBudgetAdjustEnabled && context != null) {
        await autoAdjustBudget(context);
      }
    }
  }

  // Mark goal as completed
  Future<void> markGoalAsCompleted(String id, [BuildContext? context]) async {
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index != -1) {
      final goal = _goals[index];
      final updatedGoal = goal.copyWith(
        isCompleted: true,
        currentAmount: goal.targetAmount,
      );
      _goals[index] = updatedGoal;
      notifyListeners();
      await _saveGoals();

      // If auto-adjustment is enabled and context is provided, trigger adjustment
      if (_autoBudgetAdjustEnabled &&
          context != null &&
          activeGoals.isNotEmpty) {
        await autoAdjustBudget(context);
      }
    }
  }

  // Get AI suggestions for optimizing budget based on goals
  Future<String> getGoalBasedBudgetSuggestions(
      double currentIncome, double currentBudget, context) async {
    try {
      // Format goals for the AI
      final goalsText = _goals
          .map((goal) =>
              '- ${goal.title}: ${goal.targetAmount} by ${goal.targetDate.month}/${goal.targetDate.year} (${goal.monthsRemaining} months remaining, current progress: ${goal.currentAmount})')
          .join('\n');

      // Get AI suggestions using the Gemini service
      final prompt = '''
      Based on the following financial goals and current budget, I need you to recommend a specific new budget amount.
      
      Current Monthly Income: $currentIncome
      Current Monthly Budget: $currentBudget
      
      Financial Goals:
      $goalsText
      
      Please analyze these goals and provide the following:
      
      1. IMPORTANT: Begin your response with "I recommend a budget of \$X" where X is the specific amount you recommend.
      2. Explain why this budget is appropriate for achieving these financial goals.
      3. Provide a brief explanation of how the money should be allocated to each goal.
      
      Your recommended budget must be a clear, specific number that I can extract programmatically.
      ''';

      print('Sending the following prompt to AI: $prompt');

      // Use the existing Gemini service method to get suggestions
      final currencyProvider =
          Provider.of<CurrencyProvider>(context, listen: false);

      return await _geminiService.getFinancialAdvice(
        income: currentIncome,
        expenses: 0, // We're not focusing on expenses here
        budget: currentBudget,
        transactions: [], // Not using transactions for this call
        currencyProvider: currencyProvider,
        specificQuestion: prompt,
      );
    } catch (e) {
      print('Error generating goal-based budget suggestions: $e');
      return 'Error generating goal-based budget suggestions: ${e.toString()}';
    }
  }

  // Get last budget adjustment
  BudgetAdjustment? getLastBudgetAdjustment() {
    return _lastBudgetAdjustment;
  }

  // Mark the budget adjustment as shown to user
  void markBudgetAdjustmentAsShown() {
    if (_lastBudgetAdjustment != null) {
      _lastBudgetAdjustment!.wasShown = true;
      _saveSettings();
    }
  }
}
