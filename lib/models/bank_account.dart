import 'package:flutter/material.dart';

enum BankAccountType { checking, savings, investment, credit }

extension BankAccountTypeExtension on BankAccountType {
  String toDisplayString() {
    switch (this) {
      case BankAccountType.checking:
        return 'Checking';
      case BankAccountType.savings:
        return 'Savings';
      case BankAccountType.investment:
        return 'Investment';
      case BankAccountType.credit:
        return 'Credit';
    }
  }

  static BankAccountType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'checking':
        return BankAccountType.checking;
      case 'savings':
        return BankAccountType.savings;
      case 'investment':
        return BankAccountType.investment;
      case 'credit':
        return BankAccountType.credit;
      default:
        return BankAccountType.checking;
    }
  }
}

class BankAccount {
  final String id;
  final String userId;
  final String name;
  final String accountNumber;
  final BankAccountType type;
  final double balance;
  final String bankName;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;

  BankAccount({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountNumber,
    required this.type,
    required this.balance,
    required this.bankName,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      accountNumber: json['account_number'],
      type: BankAccountTypeExtension.fromString(json['type']),
      balance: json['balance'].toDouble(),
      bankName: json['bank_name'],
      logoUrl: json['logo_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'account_number': accountNumber,
      'type': type.toString().split('.').last,
      'balance': balance,
      'bank_name': bankName,
      'logo_url': logoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_default': isDefault,
    };
  }

  BankAccount copyWith({
    String? id,
    String? userId,
    String? name,
    String? accountNumber,
    BankAccountType? type,
    double? balance,
    String? bankName,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return BankAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      bankName: bankName ?? this.bankName,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Get a masked account number for display (e.g., **** **** **** 1234)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) {
      return accountNumber;
    }

    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '•••• •••• •••• $lastFour';
  }

  // Get a color based on the account type
  Color get color {
    switch (type) {
      case BankAccountType.checking:
        return Colors.blue;
      case BankAccountType.savings:
        return Colors.green;
      case BankAccountType.investment:
        return Colors.purple;
      case BankAccountType.credit:
        return Colors.orange;
    }
  }

  // Get an icon based on the account type
  IconData get icon {
    switch (type) {
      case BankAccountType.checking:
        return Icons.account_balance;
      case BankAccountType.savings:
        return Icons.savings;
      case BankAccountType.investment:
        return Icons.trending_up;
      case BankAccountType.credit:
        return Icons.credit_card;
    }
  }
}
