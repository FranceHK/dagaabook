import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db.dart';

class PaymentsRoutes {
  Handler get handler {
    final router = Router()
      ..get('/api/payments', _getPayments)
      ..get('/api/payments/<id>', _getPaymentById)
      ..post('/api/payments', _createPayment);

    return router.call;
  }

  Future<Response> _getPayments(Request request) async {
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM payments ORDER BY date DESC',
    );

    final payments = results.map((row) {
      return {
        'id': row['id'].toString(),
        'customer_id': row['customer_id'].toString(),
        'amount': (row['amount'] as num).toDouble(),
        'date': row['date'].toIso8601String(),
        'note': row['note'],
      };
    }).toList();

    return Response.ok(
      jsonEncode(payments),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getPaymentById(Request request) async {
    final id = request.params['id'];
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM payments WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (results.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Payment not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = results.first;
    final payment = {
      'id': row['id'].toString(),
      'customer_id': row['customer_id'].toString(),
      'amount': (row['amount'] as num).toDouble(),
      'date': row['date'].toIso8601String(),
      'note': row['note'],
    };

    return Response.ok(
      jsonEncode(payment),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _createPayment(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final customerId = data['customer_id'] as String?;
    final amount = (data['amount'] as num?)?.toDouble();
    final note = data['note'] as String? ?? '';

    if (customerId == null || amount == null) {
      return Response(400,
          body: jsonEncode({'error': 'customer_id and amount are required'}),
          headers: {'Content-Type': 'application/json'});
    }

    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      '''INSERT INTO payments (customer_id, amount, note)
         VALUES (@customerId, @amount, @note)
         RETURNING *''',
      substitutionValues: {
        'customerId': customerId,
        'amount': amount,
        'note': note,
      },
    );

    final row = results.first;
    final payment = {
      'id': row['id'].toString(),
      'customer_id': row['customer_id'].toString(),
      'amount': (row['amount'] as num).toDouble(),
      'date': row['date'].toIso8601String(),
      'note': row['note'],
    };

    return Response.ok(
      jsonEncode(payment),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
