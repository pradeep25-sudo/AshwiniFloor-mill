import 'package:uuid/uuid.dart';

class Payment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime paymentDate;
  final String paymentTime;
  final DateTime createdAt;
  final String? notes;

  Payment({
    String? id,
    required this.customerId,
    required this.amount,
    required this.paymentDate,
    String? paymentTime,
    DateTime? createdAt,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        paymentTime = paymentTime ?? _formatTime(DateTime.now()),
        createdAt = createdAt ?? DateTime.now();

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().substring(0, 10),
      'payment_time': paymentTime,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
      paymentTime: map['payment_time'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      notes: map['notes'] as String?,
    );
  }
}
