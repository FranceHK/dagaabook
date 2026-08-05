/// cash/mobile settle in full immediately; credit ("mkopo/kakopa") leaves the
/// whole amount as debt; partial ("kalipa kidogo") leaves the remainder as
/// debt. All four are just bookkeeping — actual outstanding balance is
/// always `totalAmount - amountPaid`.
enum PaymentType { cash, mobile, credit, partial }

/// A single sale transaction (muuzo), always tied to the stock batch
/// (mzigo) it was sold from so inventory can be decremented correctly.
class Sale {
  final String id;
  final String stockItemId;
  final String stockType;
  final String? customerId;
  final String customerName;
  final int magunia;
  final double pricePerBag;
  final PaymentType paymentType;
  final double amountPaid;
  final DateTime date;

  const Sale({
    required this.id,
    required this.stockItemId,
    required this.stockType,
    this.customerId,
    required this.customerName,
    required this.magunia,
    required this.pricePerBag,
    required this.paymentType,
    required this.amountPaid,
    required this.date,
  });

  double get totalAmount => magunia * pricePerBag;

  double get outstanding => (totalAmount - amountPaid).clamp(0, double.infinity);

  bool get isFullyPaid => outstanding <= 0.001;
}
