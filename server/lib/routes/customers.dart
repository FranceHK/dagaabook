import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db.dart';

class CustomerRoutes {
  Handler get handler {
    final router = Router()
      ..get('/api/customers', _getCustomers)
      ..get('/api/customers/<id>', _getCustomerById)
      ..post('/api/customers', _createCustomer)
      ..get('/api/customers/<id>/debt', _getCustomerDebt);

    return router.call;
  }

  Future<Response> _getCustomers(Request request) async {
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM customers ORDER BY created_at DESC',
    );

    final customers = results.map((row) {
      return {
        'id': row['id'].toString(),
        'name': row['name'],
        'phone': row['phone'],
        'location': row['location'],
        'created_at': row['created_at'].toIso8601String(),
      };
    }).toList();

    return Response.ok(
      jsonEncode(customers),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getCustomerById(Request request) async {
    final id = request.params['id'];
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM customers WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (results.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Customer not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = results.first;
    final customer = {
      'id': row['id'].toString(),
      'name': row['name'],
      'phone': row['phone'],
      'location': row['location'],
      'created_at': row['created_at'].toIso8601String(),
    };

    return Response.ok(
      jsonEncode(customer),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _createCustomer(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final name = data['name'] as String?;
    final phone = data['phone'] as String?;
    final location = data['location'] as String? ?? '';

    if (name == null || phone == null) {
      return Response(400,
          body: jsonEncode({'error': 'name and phone are required'}),
          headers: {'Content-Type': 'application/json'});
    }

    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      '''INSERT INTO customers (name, phone, location)
         VALUES (@name, @phone, @location)
         RETURNING *''',
      substitutionValues: {
        'name': name,
        'phone': phone,
        'location': location,
      },
    );

    final row = results.first;
    final customer = {
      'id': row['id'].toString(),
      'name': row['name'],
      'phone': row['phone'],
      'location': row['location'],
      'created_at': row['created_at'].toIso8601String(),
    };

    return Response.ok(
      jsonEncode(customer),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getCustomerDebt(Request request) async {
    final id = request.params['id'];
    final conn = await Database.getConnection();

    final salesResult = await conn.mappedResultsQuery(
      '''SELECT COALESCE(SUM(magunia * price_per_bag), 0) as total_owed,
                COALESCE(SUM(amount_paid), 0) as total_paid
         FROM sales WHERE customer_id = @id''',
      substitutionValues: {'id': id},
    );

    final row = salesResult.first;
    final totalOwed = (row['total_owed'] as num).toDouble();
    final totalPaid = (row['total_paid'] as num).toDouble();
    final debt = totalOwed - totalPaid;

    final paymentsResult = await conn.mappedResultsQuery(
      '''SELECT COALESCE(SUM(amount), 0) as extra_paid
         FROM payments WHERE customer_id = @id''',
      substitutionValues: {'id': id},
    );

    final extraPaid = (paymentsResult.first['extra_paid'] as num).toDouble();
    final outstanding = debt - extraPaid;

    return Response.ok(
      jsonEncode({
        'customer_id': id,
        'total_owed': totalOwed,
        'total_paid': totalPaid + extraPaid,
        'outstanding': outstanding.clamp(0, double.infinity),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
