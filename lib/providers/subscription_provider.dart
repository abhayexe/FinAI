import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/stripe_service.dart';
import '../services/supabase_service.dart';

class SubscriptionProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _hasSubscription = false;
  Map<String, dynamic>? _subscriptionDetails;
  
  bool get isLoading => _isLoading;
  bool get hasSubscription => _hasSubscription;
  bool get isPremiumUser => _hasSubscription;
  Map<String, dynamic>? get subscriptionDetails => _subscriptionDetails;
  
  // Get subscription end date
  DateTime? get subscriptionEndDate {
    if (_subscriptionDetails != null && _subscriptionDetails!['end_date'] != null) {
      return DateTime.parse(_subscriptionDetails!['end_date']);
    }
    return null;
  }
  
  // Get subscription features
  Map<String, dynamic> get subscriptionFeatures {
    if (_subscriptionDetails != null && _subscriptionDetails!['features'] != null) {
      if (_subscriptionDetails!['features'] is String) {
        return jsonDecode(_subscriptionDetails!['features']);
      } else {
        return _subscriptionDetails!['features'];
      }
    }
    return {};
  }
  
  // Check if user has active subscription
  Future<void> checkSubscription() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _hasSubscription = await StripeService.hasActiveSubscription();
      
      if (_hasSubscription) {
        _subscriptionDetails = await StripeService.getSubscriptionDetails();
      } else {
        _subscriptionDetails = null;
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      _hasSubscription = false;
      _subscriptionDetails = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Purchase subscription
  Future<bool> purchaseSubscription() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Process payment (₹299 = 29900 paise)
      final success = await StripeService.processPayment(
        amount: 29900, // in paise
        currency: 'inr',
      );
      
      if (success) {
        await checkSubscription();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Purchase subscription with demo payment
  Future<bool> purchaseSubscriptionDemo() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Create subscription directly in Supabase
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final endDate = DateTime.now().add(const Duration(days: 30));
      
      await SupabaseService.client.from('subscriptions').upsert({
        'user_id': userId,
        'plan_name': 'Premium Financial Advisor',
        'amount_paid': 299,
        'currency': 'INR',
        'start_date': DateTime.now().toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': true,
        'features': jsonEncode({
          'advisor_hours': 2,
          'advisor_days': 30,
          'advanced_ai': true,
        }),
      });
      
      await checkSubscription();
      return true;
    } catch (e) {
      debugPrint('Error with demo subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get remaining days in subscription
  int get remainingDays {
    final endDate = subscriptionEndDate;
    if (endDate == null) return 0;
    
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }
  
  // Get advisor hours per day
  int get advisorHoursPerDay {
    return subscriptionFeatures['advisor_hours'] ?? 0;
  }
  
  // Has advanced AI
  bool get hasAdvancedAI {
    return subscriptionFeatures['advanced_ai'] ?? false;
  }
}
