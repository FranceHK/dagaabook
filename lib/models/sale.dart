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

  /// Reference of the mobile money transaction (M-Pesa, Tigo Pesa...), so a
  /// payment can be matched to the SMS/statement later. Empty for cash.
  final String transactionId;

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
    this.transactionId = '',
  });

  double get totalAmount => magunia * pricePerBag;

  double get outstanding => (totalAmount - amountPaid).clamp(0, double.infinity);

  bool get isFullyPaid => outstanding <= 0.001;

  Sale copyWith({String? customerName}) => Sale(
        id: id,
        stockItemId: stockItemId,
        stockType: stockType,
        customerId: customerId,
        customerName: customerName ?? this.customerName,
        magunia: magunia,
        pricePerBag: pricePerBag,
        paymentType: paymentType,
        amountPaid: amountPaid,
        date: date,
        transactionId: transactionId,
      );

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'],
        stockItemId: json['stock_item_id'] ?? '',
        stockType: json['stock_type'],
        customerId: json['customer_id'],
        customerName: json['customer_name'],
        magunia: json['magunia'],
        pricePerBag: (json['price_per_bag'] as num).toDouble(),
        paymentType: PaymentType.values.byName(json['payment_type']),
        amountPaid: (json['amount_paid'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        transactionId: json['transaction_id'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stock_item_id': stockItemId,
        'stock_type': stockType,
        'customer_id': customerId,
        'customer_name': customerName,
        'magunia': magunia,
        'price_per_bag': pricePerBag,
        'payment_type': paymentType.name,
        'amount_paid': amountPaid,
        'date': date.toIso8601String(),
        'transaction_id': transactionId,
      };
}
