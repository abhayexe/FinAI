import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }
    return _client!;
  }

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );
    
    // Create a profile for the new user
    if (response.user != null) {
      try {
        await createProfile(
          userId: response.user!.id,
          fullName: fullName ?? email.split('@')[0], // Use part of email as name if not provided
        );
      } catch (e) {
        debugPrint('Error creating profile: $e');
      }
    }
    
    return response;
  }

  // Create a profile for a user
  static Future<void> createProfile({
    required String userId,
    String? fullName,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName ?? 'User',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Get or create a profile for the current user
  static Future<Map<String, dynamic>?> getOrCreateCurrentUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      // Try to get the profile
      final response = await client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      // If profile exists, return it
      if (response != null) {
        return response;
      }
      
      // If profile doesn't exist, create it
      await createProfile(
        userId: currentUser!.id,
        fullName: currentUser!.email?.split('@')[0], // Use part of email as name
      );
      
      // Get the newly created profile
      final newProfile = await client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      
      return newProfile;
    } catch (e) {
      debugPrint('Error getting or creating profile: $e');
      return null;
    }
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // Ensure the user has a profile
    if (response.user != null) {
      try {
        await getOrCreateCurrentUserProfile();
      } catch (e) {
        debugPrint('Error ensuring profile exists: $e');
      }
    }
    
    return response;
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Get session
  static Session? get currentSession => client.auth.currentSession;

  // Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Update user profile
  static Future<UserResponse> updateProfile({
    required String fullName,
  }) async {
    // Update auth user data
    final response = await client.auth.updateUser(
      UserAttributes(
        data: {'full_name': fullName},
      ),
    );
    
    // Also update the profile in the profiles table
    if (currentUser != null) {
      await client.from('profiles').upsert({
        'id': currentUser!.id,
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    
    return response;
  }
}
