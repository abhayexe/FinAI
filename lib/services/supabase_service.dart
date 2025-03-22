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
          fullName: fullName ??
              email.split('@')[0], // Use part of email as name if not provided
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
        fullName:
            currentUser!.email?.split('@')[0], // Use part of email as name
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

  // Initialize bank accounts table
  static Future<void> initializeBankAccountsTable() async {
    if (currentUser == null) return;

    try {
      // Create bank_accounts table if it doesn't exist
      await client.rpc('create_bank_accounts_table_if_not_exists', params: {});
      debugPrint('Bank accounts table initialized');
    } catch (e) {
      // If RPC doesn't exist, we need to create it in Supabase SQL editor
      debugPrint('Error initializing bank accounts table: $e');
    }
  }

  // Create a stored procedure in Supabase to create the table if it doesn't exist
  // This function should be run once manually in the Supabase SQL editor
  static String getBankAccountsTableCreationSQL() {
    return '''
    create or replace function create_bank_accounts_table_if_not_exists()
    returns void as \$\$
    begin
      -- Check if the bank_accounts table exists
      if not exists (select from information_schema.tables where table_name = 'bank_accounts') then
        -- Create the bank_accounts table
        create table bank_accounts (
          id uuid primary key default uuid_generate_v4(),
          user_id uuid references auth.users(id) not null,
          name text not null,
          account_number text not null,
          type text not null,
          balance decimal not null default 0,
          bank_name text not null,
          logo_url text,
          is_default boolean not null default false,
          created_at timestamp with time zone not null default now(),
          updated_at timestamp with time zone not null default now()
        );
        
        -- Create RLS policies
        alter table bank_accounts enable row level security;
        
        -- Policy to allow users to select their own accounts
        create policy "Users can view their own accounts"
          on bank_accounts for select
          using (auth.uid() = user_id);
          
        -- Policy to allow users to insert their own accounts
        create policy "Users can insert their own accounts"
          on bank_accounts for insert
          with check (auth.uid() = user_id);
          
        -- Policy to allow users to update their own accounts
        create policy "Users can update their own accounts"
          on bank_accounts for update
          using (auth.uid() = user_id);
          
        -- Policy to allow users to delete their own accounts
        create policy "Users can delete their own accounts"
          on bank_accounts for delete
          using (auth.uid() = user_id);
          
        -- Create bank_transfers table if it doesn't exist
        if not exists (select from information_schema.tables where table_name = 'bank_transfers') then
          create table bank_transfers (
            id uuid primary key default uuid_generate_v4(),
            user_id uuid references auth.users(id) not null,
            source_account_id uuid references bank_accounts(id) not null,
            destination_account_id uuid references bank_accounts(id) not null,
            amount decimal not null,
            description text,
            status text not null,
            created_at timestamp with time zone not null default now(),
            completed_at timestamp with time zone
          );
          
          -- Create RLS policies for bank_transfers
          alter table bank_transfers enable row level security;
          
          -- Policy to allow users to select their own transfers
          create policy "Users can view their own transfers"
            on bank_transfers for select
            using (auth.uid() = user_id);
            
          -- Policy to allow users to insert their own transfers
          create policy "Users can insert their own transfers"
            on bank_transfers for insert
            with check (auth.uid() = user_id);
            
          -- Policy to allow users to update their own transfers
          create policy "Users can update their own transfers"
            on bank_transfers for update
            using (auth.uid() = user_id);
            
          -- Policy to allow users to delete their own transfers
          create policy "Users can delete their own transfers"
            on bank_transfers for delete
            using (auth.uid() = user_id);
        end if;
      end if;
    end;
    \$\$ language plpgsql;
    ''';
  }
}
