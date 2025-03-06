import 'package:uuid/uuid.dart';

class Investment {
  final String id;
  final String title;
  final String type; // mutual funds, stocks, insurance, etc.
  final double amount;
  final DateTime date;
  final String? notes;

  Investment({
    String? id,
    required this.title,
    required this.type,
    required this.amount,
    required this.date,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  Investment copyWith({
    String? id,
    String? title,
    String? type,
    double? amount,
    DateTime? date,
    String? notes,
  }) {
    return Investment(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
    );
  }
}
