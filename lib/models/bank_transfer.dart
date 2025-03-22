import 'package:flutter/material.dart';

enum TransferStatus { pending, completed, failed, cancelled }

extension TransferStatusExtension on TransferStatus {
  String toDisplayString() {
    switch (this) {
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.completed:
        return 'Completed';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  static TransferStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return TransferStatus.pending;
      case 'completed':
        return TransferStatus.completed;
      case 'failed':
        return TransferStatus.failed;
      case 'cancelled':
        return TransferStatus.cancelled;
      default:
        return TransferStatus.pending;
    }
  }

  Color get color {
    switch (this) {
      case TransferStatus.pending:
        return Colors.amber;
      case TransferStatus.completed:
        return Colors.green;
      case TransferStatus.failed:
        return Colors.red;
      case TransferStatus.cancelled:
        return Colors.grey;
    }
  }
}

class BankTransfer {
  final String id;
  final String sourceAccountId;
  final String destinationAccountId;
  final double amount;
  final String? description;
  final TransferStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String userId;
  final String? sourceAccountName;
  final String? destinationAccountName;

  BankTransfer({
    required this.id,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amount,
    this.description,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.userId,
    this.sourceAccountName,
    this.destinationAccountName,
  });

  factory BankTransfer.fromJson(Map<String, dynamic> json) {
    return BankTransfer(
      id: json['id'],
      sourceAccountId: json['source_account_id'],
      destinationAccountId: json['destination_account_id'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      status: TransferStatusExtension.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      userId: json['user_id'],
      sourceAccountName: json['source_account_name'],
      destinationAccountName: json['destination_account_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_account_id': sourceAccountId,
      'destination_account_id': destinationAccountId,
      'amount': amount,
      'description': description,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'user_id': userId,
      'source_account_name': sourceAccountName,
      'destination_account_name': destinationAccountName,
    };
  }

  BankTransfer copyWith({
    String? id,
    String? sourceAccountId,
    String? destinationAccountId,
    double? amount,
    String? description,
    TransferStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? userId,
    String? sourceAccountName,
    String? destinationAccountName,
  }) {
    return BankTransfer(
      id: id ?? this.id,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
      sourceAccountName: sourceAccountName ?? this.sourceAccountName,
      destinationAccountName:
          destinationAccountName ?? this.destinationAccountName,
    );
  }
}
