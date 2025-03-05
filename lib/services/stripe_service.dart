import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class StripeService {
  static String? _publishableKey;
  static String? _secretKey;
  
  // Initialize Stripe
  static Future<void> initialize() async {
    _publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    _secretKey = dotenv.env['STRIPE_SECRET_KEY'];
    
    if (_publishableKey == null || _publishableKey!.isEmpty) {
      throw Exception('Stripe publishable key not found in .env file');
    }
    
    Stripe.publishableKey = _publishableKey!;
    await Stripe.instance.applySettings();
  }
  
  // Create a payment intent for subscription
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount, // in smallest currency unit (paise for INR)
    required String currency,
    String? customerId,
  }) async {
    try {
      if (_secretKey == null || _secretKey!.isEmpty) {
        throw Exception('Stripe secret key not found in .env file');
      }
      
      final Map<String, dynamic> body = {
        'amount': amount.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
      };
      
      if (customerId != null) {
        body['customer'] = customerId;
      }
      
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      rethrow;
    }
  }
  
  // Process payment with card
  static Future<bool> processPayment({
    required int amount, // in smallest currency unit (paise for INR)
    required String currency,
  }) async {
    try {
      // Create payment intent
      final paymentIntentData = await createPaymentIntent(
        amount: amount,
        currency: currency,
      );
      
      if (paymentIntentData['error'] != null) {
        throw Exception(paymentIntentData['error']['message']);
      }
      
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'Finance AI App',
          style: ThemeMode.system,
        ),
      );
      
      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      // Save subscription info in Supabase
      await _saveSubscriptionInfo();
      
      return true;
    } catch (e) {
      if (e is StripeException) {
        debugPrint('Stripe error: ${e.error.localizedMessage}');
      } else {
        debugPrint('Error processing payment: $e');
      }
      return false;
    }
  }
  
  // Save subscription information in Supabase
  static Future<void> _saveSubscriptionInfo() async {
    try {
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
    } catch (e) {
      debugPrint('Error saving subscription info: $e');
      rethrow;
    }
  }
  
  // Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        return false;
      }
      
      final response = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String())
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }
  
  // Get subscription details
  static Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        return null;
      }
      
      final response = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String())
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error getting subscription details: $e');
      return null;
    }
  }
}
