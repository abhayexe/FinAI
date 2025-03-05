import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RazorpayService {
  late Razorpay _razorpay;
  final _secureStorage = const FlutterSecureStorage();
  
  // Initialize Razorpay
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onWalletSelected,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onWalletSelected);
  }

  // Dispose Razorpay instance
  void dispose() {
    _razorpay.clear();
  }

  // Connect bank account using RazorpayX API
  Future<Map<String, dynamic>> connectBankAccount({
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
  }) async {
    try {
      final url = Uri.parse('https://api.razorpay.com/v1/fund_accounts');
      final keyId = dotenv.env['RAZORPAY_KEY_ID'];
      final keySecret = dotenv.env['RAZORPAY_KEY_SECRET'];
      
      if (keyId == null || keySecret == null) {
        return {'success': false, 'message': 'Razorpay API keys not found'};
      }
      
      final String basicAuth = 'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode({
          'contact_id': await _getOrCreateContactId(),
          'account_type': 'bank_account',
          'bank_account': {
            'name': accountHolderName,
            'ifsc': ifscCode,
            'account_number': accountNumber,
          },
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Save fund account ID for future use
        await _secureStorage.write(
          key: 'razorpay_fund_account_id',
          value: responseData['id'],
        );
        
        return {
          'success': true,
          'message': 'Bank account connected successfully',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error']['description'] ?? 'Failed to connect bank account',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Get bank account details
  Future<Map<String, dynamic>> getBankAccountDetails() async {
    try {
      final fundAccountId = await _secureStorage.read(key: 'razorpay_fund_account_id');
      
      if (fundAccountId == null) {
        return {'success': false, 'message': 'No bank account connected'};
      }
      
      final url = Uri.parse('https://api.razorpay.com/v1/fund_accounts/$fundAccountId');
      final keyId = dotenv.env['RAZORPAY_KEY_ID'];
      final keySecret = dotenv.env['RAZORPAY_KEY_SECRET'];
      
      if (keyId == null || keySecret == null) {
        return {'success': false, 'message': 'Razorpay API keys not found'};
      }
      
      final String basicAuth = 'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error']['description'] ?? 'Failed to get bank account details',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // Helper method to get or create contact ID
  Future<String> _getOrCreateContactId() async {
    final existingContactId = await _secureStorage.read(key: 'razorpay_contact_id');
    
    if (existingContactId != null) {
      return existingContactId;
    }
    
    // Create a new contact
    final url = Uri.parse('https://api.razorpay.com/v1/contacts');
    final keyId = dotenv.env['RAZORPAY_KEY_ID'];
    final keySecret = dotenv.env['RAZORPAY_KEY_SECRET'];
    
    final String basicAuth = 'Basic ${base64Encode(utf8.encode('$keyId:$keySecret'))}';
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuth,
      },
      body: jsonEncode({
        'name': 'User', // This should be replaced with actual user data
        'email': 'user@example.com', // This should be replaced with actual user data
        'contact': '9999999999', // This should be replaced with actual user data
        'type': 'customer',
      }),
    );
    
    final responseData = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      final contactId = responseData['id'];
      await _secureStorage.write(key: 'razorpay_contact_id', value: contactId);
      return contactId;
    } else {
      throw Exception('Failed to create contact: ${responseData['error']['description']}');
    }
  }
}
