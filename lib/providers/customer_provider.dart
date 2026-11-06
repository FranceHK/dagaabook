import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../services/local_store.dart';

/// Manages Wateja (customers) and the Malipo (payments) they make toward
/// outstanding debt. Saved on this device.
class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [];
  final List<Payment> _payments = [];
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
      final results = await Future.wait([
        LocalStore.loadList(LocalStore.customersKey, Customer.fromJson),
        LocalStore.loadList(LocalStore.paymentsKey, Payment.fromJson),
      ]);
      _customers
        ..clear()
        ..addAll(results[0] as List<Customer>);
      _payments
        ..clear()
        ..addAll(results[1] as List<Payment>);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCustomers() =>
      LocalStore.saveList(LocalStore.customersKey, _customers.map((c) => c.toJson()).toList());

  Future<void> _savePayments() =>
      LocalStore.saveList(LocalStore.paymentsKey, _payments.map((p) => p.toJson()).toList());

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
    final customer = Customer(
      id: LocalStore.newId('cust'),
      name: name,
      phone: phone,
      location: location,
      createdAt: DateTime.now(),
    );
    _customers.add(customer);
    notifyListeners();
    await _saveCustomers();
    return customer;
  }

  Future<Customer> updateCustomer(
    String id, {
    required String name,
    required String phone,
    String location = '',
  }) async {
    final index = _customers.indexWhere((c) => c.id == id);
    final updated = _customers[index].copyWith(name: name, phone: phone, location: location);
    _customers[index] = updated;
    notifyListeners();
    await _saveCustomers();
    return updated;
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String note = '',
    String method = 'cash',
    String transactionId = '',
    DateTime? date,
  }) async {
    _payments.add(Payment(
      id: LocalStore.newId('pay'),
      customerId: customerId,
      amount: amount,
      date: date ?? DateTime.now(),
      note: note,
      method: method,
      transactionId: transactionId,
    ));
    notifyListeners();
    await _savePayments();
  }
}
