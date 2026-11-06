import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/local_store.dart';

/// Manages Mauzo (sales transactions). Saved on this device.
class SalesProvider extends ChangeNotifier {
  final List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<Sale> get sales {
    final list = List<Sale>.from(_sales);
    list.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(list);
  }

  List<Sale> get today {
    final now = DateTime.now();
    return sales.where((s) => s.date.year == now.year && s.date.month == now.month && s.date.day == now.day).toList();
  }

  double get totalRevenueToday => today.fold(0.0, (sum, s) => sum + s.totalAmount);

  bool get isLoading => _isLoading;
  String? get error => _error;

  SalesProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final salesData = await LocalStore.loadList(LocalStore.salesKey, Sale.fromJson);
      _sales
        ..clear()
        ..addAll(salesData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Sale> salesForCustomer(String customerId) {
    return sales.where((s) => s.customerId == customerId).toList();
  }

  double creditOutstandingForCustomer(String customerId) {
    return salesForCustomer(customerId).fold(0.0, (sum, s) => sum + s.outstanding);
  }

  /// Sales keep a copy of the customer's name, so update it after a rename.
  Future<void> renameCustomer(String customerId, String name) async {
    var changed = false;
    for (var i = 0; i < _sales.length; i++) {
      if (_sales[i].customerId == customerId && _sales[i].customerName != name) {
        _sales[i] = _sales[i].copyWith(customerName: name);
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    await LocalStore.saveList(LocalStore.salesKey, _sales.map((s) => s.toJson()).toList());
  }

  Future<Sale> addSale({
    required String stockItemId,
    required String stockType,
    String? customerId,
    required String customerName,
    required int magunia,
    required double pricePerBag,
    required PaymentType paymentType,
    required double amountPaid,
    String transactionId = '',
    DateTime? date,
  }) async {
    final sale = Sale(
      id: LocalStore.newId('sale'),
      stockItemId: stockItemId,
      stockType: stockType,
      customerId: customerId,
      customerName: customerName,
      magunia: magunia,
      pricePerBag: pricePerBag,
      paymentType: paymentType,
      amountPaid: amountPaid,
      date: date ?? DateTime.now(),
      transactionId: transactionId,
    );
    _sales.add(sale);
    notifyListeners();
    await LocalStore.saveList(LocalStore.salesKey, _sales.map((s) => s.toJson()).toList());
    return sale;
  }
}
