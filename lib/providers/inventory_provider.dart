import 'package:flutter/foundation.dart';
import '../models/stock_item.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';

/// Manages Mizigo (inventory) stock entries, tracked by magunia (bags).
/// Falls back to local data when the API server is unavailable.
class InventoryProvider extends ChangeNotifier {
  final List<StockItem> _items = [];
  int _counter = 100;
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
      if (await ApiService.checkConnection()) {
        final stock = await ApiService.getStock();
        _items.clear();
        _items.addAll(stock);
      } else {
        _items.clear();
        _items.addAll(MockDataService.seedStock());
      }
    } catch (e) {
      _items.clear();
      _items.addAll(MockDataService.seedStock());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    if (ApiService.isAvailable) {
      final item = await ApiService.createStock(
        type: type,
        totalMagunia: totalMagunia,
        purchasePricePerBag: purchasePricePerBag,
        sellingPricePerBag: sellingPricePerBag,
        supplier: supplier,
      );
      _items.add(item);
    } else {
      _items.add(StockItem(
        id: 'local_${_counter++}',
        type: type,
        totalMagunia: totalMagunia,
        purchasePricePerBag: purchasePricePerBag,
        sellingPricePerBag: sellingPricePerBag,
        dateAdded: DateTime.now(),
        supplier: supplier,
      ));
    }
    notifyListeners();
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
  }
}
