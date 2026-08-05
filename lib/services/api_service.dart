import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer.dart';
import '../models/payment.dart';
import '../models/sale.dart';
import '../models/stock_item.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 3);

  static final http.Client _client = http.Client();

  static bool isAvailable = false;

  static Future<bool> checkConnection() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(timeout);
      isAvailable = response.statusCode == 200;
    } catch (_) {
      isAvailable = false;
    }
    return isAvailable;
  }

  // ==================== CUSTOMERS ====================

  static Future<List<Customer>> getCustomers() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/customers'))
        .timeout(timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Customer(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        location: json['location'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
      )).toList();
    }
    throw Exception('Failed to load customers: ${response.statusCode}');
  }

  static Future<Customer> createCustomer({
    required String name,
    required String phone,
    String location = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/customers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'phone': phone, 'location': location}),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Customer(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        location: json['location'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
      );
    }
    throw Exception('Failed to create customer: ${response.body}');
  }

  static Future<Map<String, dynamic>> getCustomerDebt(String customerId) async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/customers/$customerId/debt'))
        .timeout(timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load customer debt: ${response.statusCode}');
  }

  // ==================== STOCK ====================

  static Future<List<StockItem>> getStock() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/stock'))
        .timeout(timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => StockItem(
        id: json['id'],
        type: json['type'],
        totalMagunia: json['total_magunia'],
        soldMagunia: json['sold_magunia'],
        purchasePricePerBag: (json['purchase_price_per_bag'] as num).toDouble(),
        sellingPricePerBag: (json['selling_price_per_bag'] as num).toDouble(),
        dateAdded: DateTime.parse(json['date_added']),
        supplier: json['supplier'] ?? '',
      )).toList();
    }
    throw Exception('Failed to load stock: ${response.statusCode}');
  }

  static Future<StockItem> createStock({
    required String type,
    required int totalMagunia,
    required double purchasePricePerBag,
    required double sellingPricePerBag,
    String supplier = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/stock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'total_magunia': totalMagunia,
        'purchase_price_per_bag': purchasePricePerBag,
        'selling_price_per_bag': sellingPricePerBag,
        'supplier': supplier,
      }),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return StockItem(
        id: json['id'],
        type: json['type'],
        totalMagunia: json['total_magunia'],
        soldMagunia: json['sold_magunia'],
        purchasePricePerBag: (json['purchase_price_per_bag'] as num).toDouble(),
        sellingPricePerBag: (json['selling_price_per_bag'] as num).toDouble(),
        dateAdded: DateTime.parse(json['date_added']),
        supplier: json['supplier'] ?? '',
      );
    }
    throw Exception('Failed to create stock: ${response.body}');
  }

  // ==================== SALES ====================

  static Future<List<Sale>> getSales() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/sales'))
        .timeout(timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Sale(
        id: json['id'],
        stockItemId: json['stock_item_id'] ?? '',
        stockType: json['stock_type'],
        customerId: json['customer_id'],
        customerName: json['customer_name'],
        magunia: json['magunia'],
        pricePerBag: (json['price_per_bag'] as num).toDouble(),
        paymentType: PaymentType.values.firstWhere(
          (e) => e.name == json['payment_type'],
        ),
        amountPaid: (json['amount_paid'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      )).toList();
    }
    throw Exception('Failed to load sales: ${response.statusCode}');
  }

  static Future<Sale> createSale({
    required String stockItemId,
    required String stockType,
    String? customerId,
    required String customerName,
    required int magunia,
    required double pricePerBag,
    required PaymentType paymentType,
    required double amountPaid,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/sales'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'stock_item_id': stockItemId,
        'stock_type': stockType,
        'customer_id': customerId,
        'customer_name': customerName,
        'magunia': magunia,
        'price_per_bag': pricePerBag,
        'payment_type': paymentType.name,
        'amount_paid': amountPaid,
      }),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Sale(
        id: json['id'],
        stockItemId: json['stock_item_id'] ?? '',
        stockType: json['stock_type'],
        customerId: json['customer_id'],
        customerName: json['customer_name'],
        magunia: json['magunia'],
        pricePerBag: (json['price_per_bag'] as num).toDouble(),
        paymentType: PaymentType.values.firstWhere(
          (e) => e.name == json['payment_type'],
        ),
        amountPaid: (json['amount_paid'] as num).toDouble(),
        date: DateTime.parse(json['date']),
      );
    }
    throw Exception('Failed to create sale: ${response.body}');
  }

  // ==================== PAYMENTS ====================

  static Future<List<Payment>> getPayments() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/api/payments'))
        .timeout(timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Payment(
        id: json['id'],
        customerId: json['customer_id'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        note: json['note'] ?? '',
      )).toList();
    }
    throw Exception('Failed to load payments: ${response.statusCode}');
  }

  static Future<Payment> createPayment({
    required String customerId,
    required double amount,
    String note = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/payments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customer_id': customerId, 'amount': amount, 'note': note}),
    ).timeout(timeout);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Payment(
        id: json['id'],
        customerId: json['customer_id'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        note: json['note'] ?? '',
      );
    }
    throw Exception('Failed to create payment: ${response.body}');
  }
}
