import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';

/// Manages Mauzo (sales transactions). Falls back to local data when the API server is unavailable.
class SalesProvider extends ChangeNotifier {
  final List<Sale> _sales = [];
  int _counter = 100;
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
      if (await ApiService.checkConnection()) {
        final salesData = await ApiService.getSales();
        _sales.clear();
        _sales.addAll(salesData);
      } else {
        _sales.clear();
        _sales.addAll(MockDataService.seedSales());
      }
    } catch (e) {
      _sales.clear();
      _sales.addAll(MockDataService.seedSales());
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

  Future<Sale> addSale({
    required String stockItemId,
    required String stockType,
    String? customerId,
    required String customerName,
    required int magunia,
    required double pricePerBag,
    required PaymentType paymentType,
    required double amountPaid,
    DateTime? date,
  }) async {
    Sale sale;
    if (ApiService.isAvailable) {
      sale = await ApiService.createSale(
        stockItemId: stockItemId,
        stockType: stockType,
        customerId: customerId,
        customerName: customerName,
        magunia: magunia,
        pricePerBag: pricePerBag,
        paymentType: paymentType,
        amountPaid: amountPaid,
      );
    } else {
      sale = Sale(
        id: 'local_sale_${_counter++}',
        stockItemId: stockItemId,
        stockType: stockType,
        customerId: customerId,
        customerName: customerName,
        magunia: magunia,
        pricePerBag: pricePerBag,
        paymentType: paymentType,
        amountPaid: amountPaid,
        date: date ?? DateTime.now(),
      );
    }
    _sales.add(sale);
    notifyListeners();
    return sale;
  }
}
