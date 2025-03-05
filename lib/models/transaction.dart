class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isRecurring;
  final int? recurringDay;
  final String? recurringFrequency;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.isRecurring = false,
    this.recurringDay,
    this.recurringFrequency,
  });

  // Convert Transaction to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'isRecurring': isRecurring,
      'recurringDay': recurringDay,
      'recurringFrequency': recurringFrequency,
    };
  }

  // Create Transaction from Map
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: json['amount'] as double,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringDay: json['recurringDay'] as int?,
      recurringFrequency: json['recurringFrequency'] as String?,
    );
  }

  // Create a copy of the transaction with updated values
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    bool? isRecurring,
    int? recurringDay,
    String? recurringFrequency,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringDay: recurringDay ?? this.recurringDay,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
    );
  }
}
