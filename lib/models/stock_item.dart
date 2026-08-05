/// A batch of dagaa stock received into inventory, tracked by magunia (bags)
/// rather than loose kg — this matches how wholesale dagaa is actually
/// bought and sold in Mwanza.
///
/// `id` is a local mock identifier; when the backend is connected this
/// should map 1:1 to the Neon Postgres primary key.
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
}
