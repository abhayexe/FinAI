import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bank_account.dart';
import '../models/bank_transfer.dart';
import '../services/supabase_service.dart';

class BankAccountProvider with ChangeNotifier {
  List<BankAccount> _accounts = [];
  List<BankTransfer> _transfers = [];
  BankAccount? _selectedAccount;
  bool _isLoading = false;

  List<BankAccount> get accounts => [..._accounts];
  List<BankTransfer> get transfers => [..._transfers];
  BankAccount? get selectedAccount => _selectedAccount;
  bool get isLoading => _isLoading;

  // Get the default account or the first account if no default is set
  BankAccount? get defaultAccount {
    final defaultAccounts = _accounts.where((account) => account.isDefault);
    if (defaultAccounts.isNotEmpty) {
      return defaultAccounts.first;
    } else if (_accounts.isNotEmpty) {
      return _accounts.first;
    }
    return null;
  }

  // Get the total balance across all accounts
  double get totalBalance {
    return _accounts.fold(0, (sum, account) => sum + account.balance);
  }

  // Load accounts for the current user
  Future<void> loadAccounts() async {
    if (!SupabaseService.isAuthenticated) return;

    _isLoading = true;
    notifyListeners();

    try {
      // First, ensure that the bank_accounts table exists
      await SupabaseService.initializeBankAccountsTable();

      final userId = SupabaseService.currentUser!.id;
      final response = await SupabaseService.client
          .from('bank_accounts')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at');

      _accounts = (response as List)
          .map((account) =>
              BankAccount.fromJson(account as Map<String, dynamic>))
          .toList();

      // Set the selected account to the default or first account
      _selectedAccount = defaultAccount;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bank accounts: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Add a new bank account
  Future<BankAccount> addAccount({
    required String name,
    required String accountNumber,
    required BankAccountType type,
    required double initialBalance,
    required String bankName,
    String? logoUrl,
    bool isDefault = false,
  }) async {
    if (!SupabaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // First, ensure that the bank_accounts table exists
      await SupabaseService.initializeBankAccountsTable();

      final userId = SupabaseService.currentUser!.id;
      final now = DateTime.now();

      // If this is the first account or marked as default, unset any existing default
      if (isDefault || _accounts.isEmpty) {
        await _unsetDefaultAccounts();
      }

      final newAccountData = {
        'user_id': userId,
        'name': name,
        'account_number': accountNumber,
        'type': type.toString().split('.').last,
        'balance': initialBalance,
        'bank_name': bankName,
        'logo_url': logoUrl,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'is_default': isDefault ||
            _accounts.isEmpty, // First account is default by default
      };

      final response = await SupabaseService.client
          .from('bank_accounts')
          .insert(newAccountData)
          .select()
          .single();

      final newAccount = BankAccount.fromJson(response as Map<String, dynamic>);

      _accounts.add(newAccount);

      // If this is the first account or set as default, select it
      if (_accounts.length == 1 || newAccount.isDefault) {
        _selectedAccount = newAccount;
      }

      _isLoading = false;
      notifyListeners();
      return newAccount;
    } catch (e) {
      debugPrint('Error adding bank account: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update an existing bank account
  Future<BankAccount> updateAccount({
    required String accountId,
    String? name,
    String? accountNumber,
    BankAccountType? type,
    double? balance,
    String? bankName,
    String? logoUrl,
    bool? isDefault,
  }) async {
    if (!SupabaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // If setting this account as default, unset any existing default
      if (isDefault == true) {
        await _unsetDefaultAccounts();
      }

      final Map<String, dynamic> updateData = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (accountNumber != null) updateData['account_number'] = accountNumber;
      if (type != null) updateData['type'] = type.toString().split('.').last;
      if (balance != null) updateData['balance'] = balance;
      if (bankName != null) updateData['bank_name'] = bankName;
      if (logoUrl != null) updateData['logo_url'] = logoUrl;
      if (isDefault != null) updateData['is_default'] = isDefault;

      final response = await SupabaseService.client
          .from('bank_accounts')
          .update(updateData)
          .eq('id', accountId)
          .select()
          .single();

      final updatedAccount =
          BankAccount.fromJson(response as Map<String, dynamic>);

      // Update the account in the local list
      final index = _accounts.indexWhere((account) => account.id == accountId);
      if (index != -1) {
        _accounts[index] = updatedAccount;
      }

      // If this is the selected account, update it
      if (_selectedAccount?.id == accountId) {
        _selectedAccount = updatedAccount;
      }

      _isLoading = false;
      notifyListeners();
      return updatedAccount;
    } catch (e) {
      debugPrint('Error updating bank account: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Delete a bank account
  Future<void> deleteAccount(String accountId) async {
    if (!SupabaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.client
          .from('bank_accounts')
          .delete()
          .eq('id', accountId);

      // Remove the account from the local list
      _accounts.removeWhere((account) => account.id == accountId);

      // If this was the selected account, select another account
      if (_selectedAccount?.id == accountId) {
        _selectedAccount = defaultAccount;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting bank account: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Set an account as the default
  Future<void> setDefaultAccount(String accountId) async {
    if (!SupabaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Unset any existing default accounts
      await _unsetDefaultAccounts();

      // Set the new default account
      await SupabaseService.client.from('bank_accounts').update({
        'is_default': true,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', accountId);

      // Update the local accounts
      for (int i = 0; i < _accounts.length; i++) {
        if (_accounts[i].id == accountId) {
          _accounts[i] = _accounts[i].copyWith(isDefault: true);
        }
      }

      // Update selected account if needed
      if (_selectedAccount?.id == accountId) {
        _selectedAccount =
            _accounts.firstWhere((account) => account.id == accountId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting default account: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Set the selected account
  void selectAccount(String accountId) {
    final account = _accounts.firstWhere(
      (account) => account.id == accountId,
      orElse: () => throw Exception('Account not found'),
    );

    _selectedAccount = account;
    notifyListeners();
  }

  // Helper method to unset all default accounts
  Future<void> _unsetDefaultAccounts() async {
    await SupabaseService.client.from('bank_accounts').update(
        {'is_default': false}).eq('user_id', SupabaseService.currentUser!.id);

    // Update local accounts
    for (int i = 0; i < _accounts.length; i++) {
      _accounts[i] = _accounts[i].copyWith(isDefault: false);
    }
  }

  // Load transfers for the current user
  Future<void> loadTransfers() async {
    if (!SupabaseService.isAuthenticated) return;

    _isLoading = true;
    notifyListeners();

    try {
      // First, ensure that the bank_accounts and bank_transfers tables exist
      await SupabaseService.initializeBankAccountsTable();

      final userId = SupabaseService.currentUser!.id;
      final response = await SupabaseService.client
          .from('bank_transfers')
          .select(
              '*, source_account:bank_accounts!bank_transfers_source_account_id_fkey(name), destination_account:bank_accounts!bank_transfers_destination_account_id_fkey(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _transfers = (response as List).map((transfer) {
        // Extract the account names from the joined data
        final sourceAccountName = transfer['source_account'] != null
            ? transfer['source_account']['name'] as String
            : null;
        final destinationAccountName = transfer['destination_account'] != null
            ? transfer['destination_account']['name'] as String
            : null;

        // Create a flattened version of the transfer data
        final Map<String, dynamic> transferData = {
          ...transfer as Map<String, dynamic>,
          'source_account_name': sourceAccountName,
          'destination_account_name': destinationAccountName,
        };

        return BankTransfer.fromJson(transferData);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bank transfers: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Create a new transfer between accounts
  Future<BankTransfer> createTransfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required double amount,
    String? description,
  }) async {
    if (!SupabaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    if (sourceAccountId == destinationAccountId) {
      throw Exception('Source and destination accounts cannot be the same');
    }

    if (amount <= 0) {
      throw Exception('Transfer amount must be greater than zero');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = SupabaseService.currentUser!.id;
      final now = DateTime.now();
      final uuid = const Uuid();

      // Verify the accounts exist and belong to the user
      final sourceAccount = _accounts.firstWhere(
        (account) => account.id == sourceAccountId,
        orElse: () => throw Exception('Source account not found'),
      );

      final destinationAccount = _accounts.firstWhere(
        (account) => account.id == destinationAccountId,
        orElse: () => throw Exception('Destination account not found'),
      );

      // Check if the source account has sufficient funds
      if (sourceAccount.balance < amount) {
        throw Exception('Insufficient funds in the source account');
      }

      // Create the transfer
      final transferData = {
        'id': uuid.v4(),
        'source_account_id': sourceAccountId,
        'destination_account_id': destinationAccountId,
        'amount': amount,
        'description': description,
        'status': TransferStatus.pending.toString().split('.').last,
        'created_at': now.toIso8601String(),
        'user_id': userId,
      };

      final transferResponse = await SupabaseService.client
          .from('bank_transfers')
          .insert(transferData)
          .select()
          .single();

      // Process the transfer immediately (in a real app, this might be handled by a backend process)

      // 1. Update source account (deduct amount)
      final updatedSourceAccount = await updateAccount(
        accountId: sourceAccountId,
        balance: sourceAccount.balance - amount,
      );

      // 2. Update destination account (add amount)
      final updatedDestinationAccount = await updateAccount(
        accountId: destinationAccountId,
        balance: destinationAccount.balance + amount,
      );

      // 3. Mark transfer as completed
      final completedTransferData = {
        'status': TransferStatus.completed.toString().split('.').last,
        'completed_at': now.toIso8601String(),
      };

      final completedTransferResponse = await SupabaseService.client
          .from('bank_transfers')
          .update(completedTransferData)
          .eq('id', transferResponse['id'])
          .select(
              '*, source_account:bank_accounts!bank_transfers_source_account_id_fkey(name), destination_account:bank_accounts!bank_transfers_destination_account_id_fkey(name)')
          .single();

      // Extract account names and create a flattened transfer object
      final sourceAccountName =
          completedTransferResponse['source_account']['name'] as String;
      final destinationAccountName =
          completedTransferResponse['destination_account']['name'] as String;

      final Map<String, dynamic> transferWithNames = {
        ...completedTransferResponse as Map<String, dynamic>,
        'source_account_name': sourceAccountName,
        'destination_account_name': destinationAccountName,
      };

      final transfer = BankTransfer.fromJson(transferWithNames);

      // Add to local transfers list
      _transfers.insert(0, transfer);

      _isLoading = false;
      notifyListeners();
      return transfer;
    } catch (e) {
      debugPrint('Error creating transfer: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
