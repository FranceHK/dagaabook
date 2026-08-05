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
}
