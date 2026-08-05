import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';

/// Manages Wateja (customers) and the Malipo (payments) they make toward
/// outstanding debt. Falls back to local data when the API server is unavailable.
class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [];
  final List<Payment> _payments = [];
  int _customerCounter = 100;
  int _paymentCounter = 100;
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => List.unmodifiable(_customers);
  List<Payment> get payments => List.unmodifiable(_payments);
  bool get isLoading => _isLoading;
  String? get error => _error;

  CustomerProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await ApiService.checkConnection()) {
        final results = await Future.wait([
          ApiService.getCustomers(),
          ApiService.getPayments(),
        ]);
        _customers.clear();
        _customers.addAll(results[0] as List<Customer>);
        _payments.clear();
        _payments.addAll(results[1] as List<Payment>);
      } else {
        _customers.clear();
        _customers.addAll(MockDataService.seedCustomers());
        _payments.clear();
        _payments.addAll(MockDataService.seedPayments());
      }
    } catch (e) {
      _customers.clear();
      _customers.addAll(MockDataService.seedCustomers());
      _payments.clear();
      _payments.addAll(MockDataService.seedPayments());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Customer? byId(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Payment> paymentsForCustomer(String customerId) {
    final list = _payments.where((p) => p.customerId == customerId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double totalPaidByCustomer(String customerId) {
    return paymentsForCustomer(customerId).fold(0.0, (sum, p) => sum + p.amount);
  }

  Future<Customer> addCustomer({
    required String name,
    required String phone,
    String location = '',
  }) async {
    Customer customer;
    if (ApiService.isAvailable) {
      customer = await ApiService.createCustomer(
        name: name,
        phone: phone,
        location: location,
      );
    } else {
      customer = Customer(
        id: 'local_cust_${_customerCounter++}',
        name: name,
        phone: phone,
        location: location,
        createdAt: DateTime.now(),
      );
    }
    _customers.add(customer);
    notifyListeners();
    return customer;
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String note = '',
    DateTime? date,
  }) async {
    Payment payment;
    if (ApiService.isAvailable) {
      payment = await ApiService.createPayment(
        customerId: customerId,
        amount: amount,
        note: note,
      );
    } else {
      payment = Payment(
        id: 'local_pay_${_paymentCounter++}',
        customerId: customerId,
        amount: amount,
        date: date ?? DateTime.now(),
        note: note,
      );
    }
    _payments.add(payment);
    notifyListeners();
  }
}
