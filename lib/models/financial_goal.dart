import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class FinancialGoal {
  final String id;
  final String title;
  final String description;
  final double targetAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final Color color;
  double currentAmount;
  bool isCompleted;

  FinancialGoal({
    String? id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.targetDate,
    required this.color,
    this.currentAmount = 0.0,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // Calculate progress percentage
  double get progressPercentage =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  // Calculate remaining amount
  double get remainingAmount => targetAmount - currentAmount;

  // Calculate months remaining until target date
  int get monthsRemaining {
    final now = DateTime.now();
    return (targetDate.year - now.year) * 12 + targetDate.month - now.month;
  }

  // Monthly amount needed to reach goal
  double get monthlyAmountNeeded {
    final months = monthsRemaining;
    return months > 0 ? remainingAmount / months : remainingAmount;
  }

  // Create a copy of this goal with updated fields
  FinancialGoal copyWith({
    String? title,
    String? description,
    double? targetAmount,
    DateTime? targetDate,
    Color? color,
    double? currentAmount,
    bool? isCompleted,
  }) {
    return FinancialGoal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      color: color ?? this.color,
      currentAmount: currentAmount ?? this.currentAmount,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'color': color.value,
      'currentAmount': currentAmount,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create from Map
  factory FinancialGoal.fromMap(Map<String, dynamic> map) {
    return FinancialGoal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      targetAmount: map['targetAmount'],
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate']),
      color: Color(map['color']),
      currentAmount: map['currentAmount'],
      isCompleted: map['isCompleted'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory FinancialGoal.fromJson(Map<String, dynamic> json) =>
      FinancialGoal.fromMap(json);
}
