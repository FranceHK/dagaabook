/// A partial or full payment made by a customer against their debt (malipo).
class Payment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String note;

  /// 'cash' or 'mobile'.
  final String method;

  /// Mobile money transaction reference; empty for cash.
  final String transactionId;

  bool get isMobile => method == 'mobile';

  const Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    this.note = '',
    this.method = 'cash',
    this.transactionId = '',
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        customerId: json['customer_id'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        note: json['note'] ?? '',
        method: json['method'] ?? 'cash',
        transactionId: json['transaction_id'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        'method': method,
        'transaction_id': transactionId,
      };
}
