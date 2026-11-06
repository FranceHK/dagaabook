import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';
import '../services/local_store.dart';

/// Manages Mizigo (inventory) stock entries, tracked by magunia (bags).
/// Saved on this device.
class InventoryProvider extends ChangeNotifier {
  final List<StockItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<StockItem> get items => List.unmodifiable(_items..sort((a, b) => b.dateAdded.compareTo(a.dateAdded)));
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalMaguniaIn => _items.fold(0, (sum, item) => sum + item.totalMagunia);
  int get totalMaguniaRemaining => _items.fold(0, (sum, item) => sum + item.remainingMagunia);
  double get totalStockValue => _items.fold(0.0, (sum, item) => sum + item.totalPurchaseValue);
  double get remainingStockValue => _items.fold(0.0, (sum, item) => sum + item.remainingStockValue);

  InventoryProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final stock = await LocalStore.loadList(LocalStore.stockKey, StockItem.fromJson);
      _items
        ..clear()
        ..addAll(stock);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _save() =>
      LocalStore.saveList(LocalStore.stockKey, _items.map((i) => i.toJson()).toList());

  StockItem? byId(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addStock({
    required String type,
    required int totalMagunia,
    required double purchasePricePerBag,
    required double sellingPricePerBag,
    String supplier = '',
  }) async {
    _items.add(StockItem(
      id: LocalStore.newId('stock'),
      type: type,
      totalMagunia: totalMagunia,
      purchasePricePerBag: purchasePricePerBag,
      sellingPricePerBag: sellingPricePerBag,
      dateAdded: DateTime.now(),
      supplier: supplier,
    ));
    notifyListeners();
    await _save();
  }

  void recordSale({required String stockItemId, required int magunia}) {
    final index = _items.indexWhere((i) => i.id == stockItemId);
    if (index == -1) return;
    final item = _items[index];
    if (magunia > item.remainingMagunia) {
      throw StateError('Insufficient stock');
    }
    _items[index] = item.copyWith(soldMagunia: item.soldMagunia + magunia);
    notifyListeners();
    _save();
  }
}
