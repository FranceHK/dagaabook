/// A partial or full payment made by a customer against their debt (malipo).
class Payment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String note;

  const Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        customerId: json['customer_id'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        note: json['note'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };
}
