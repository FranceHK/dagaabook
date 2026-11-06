import 'sale.dart';

/// A batch of dagaa stock received into inventory, tracked by magunia (bags)
/// rather than loose kg — this matches how wholesale dagaa is actually
/// bought and sold in Mwanza.
class StockItem {
  final String id;
  final String type;
  final int totalMagunia;
  final int soldMagunia;
  final double purchasePricePerBag;
  final double sellingPricePerBag;
  final DateTime dateAdded;
  final String supplier;

  const StockItem({
    required this.id,
    required this.type,
    required this.totalMagunia,
    this.soldMagunia = 0,
    required this.purchasePricePerBag,
    required this.sellingPricePerBag,
    required this.dateAdded,
    this.supplier = '',
  });

  int get remainingMagunia => totalMagunia - soldMagunia;

  bool get isSoldOut => remainingMagunia <= 0;

  double get totalPurchaseValue => totalMagunia * purchasePricePerBag;

  double get remainingStockValue => remainingMagunia * purchasePricePerBag;

  /// Planned profit on one bag at the listed selling price.
  double get profitPerBag => sellingPricePerBag - purchasePricePerBag;

  /// Profit actually made on this batch, using the price each bag sold for.
  double profitEarned(Iterable<Sale> sales) => sales
      .where((s) => s.stockItemId == id)
      .fold(0.0, (sum, s) => sum + s.magunia * (s.pricePerBag - purchasePricePerBag));

  StockItem copyWith({
    String? id,
    String? type,
    int? totalMagunia,
    int? soldMagunia,
    double? purchasePricePerBag,
    double? sellingPricePerBag,
    DateTime? dateAdded,
    String? supplier,
  }) {
    return StockItem(
      id: id ?? this.id,
      type: type ?? this.type,
      totalMagunia: totalMagunia ?? this.totalMagunia,
      soldMagunia: soldMagunia ?? this.soldMagunia,
      purchasePricePerBag: purchasePricePerBag ?? this.purchasePricePerBag,
      sellingPricePerBag: sellingPricePerBag ?? this.sellingPricePerBag,
      dateAdded: dateAdded ?? this.dateAdded,
      supplier: supplier ?? this.supplier,
    );
  }

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        id: json['id'],
        type: json['type'],
        totalMagunia: json['total_magunia'],
        soldMagunia: json['sold_magunia'] ?? 0,
        purchasePricePerBag: (json['purchase_price_per_bag'] as num).toDouble(),
        sellingPricePerBag: (json['selling_price_per_bag'] as num).toDouble(),
        dateAdded: DateTime.parse(json['date_added']),
        supplier: json['supplier'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'total_magunia': totalMagunia,
        'sold_magunia': soldMagunia,
        'purchase_price_per_bag': purchasePricePerBag,
        'selling_price_per_bag': sellingPricePerBag,
        'date_added': dateAdded.toIso8601String(),
        'supplier': supplier,
      };
}
