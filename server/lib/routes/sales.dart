import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db.dart';

class SalesRoutes {
  Handler get handler {
    final router = Router()
      ..get('/api/sales', _getSales)
      ..get('/api/sales/<id>', _getSaleById)
      ..post('/api/sales', _createSale);

    return router.call;
  }

  Future<Response> _getSales(Request request) async {
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM sales ORDER BY date DESC',
    );

    final sales = results.map((row) {
      return {
        'id': row['id'].toString(),
        'stock_item_id': row['stock_item_id']?.toString(),
        'stock_type': row['stock_type'],
        'customer_id': row['customer_id']?.toString(),
        'customer_name': row['customer_name'],
        'magunia': row['magunia'],
        'price_per_bag': (row['price_per_bag'] as num).toDouble(),
        'payment_type': row['payment_type'],
        'amount_paid': (row['amount_paid'] as num).toDouble(),
        'date': row['date'].toIso8601String(),
      };
    }).toList();

    return Response.ok(
      jsonEncode(sales),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getSaleById(Request request) async {
    final id = request.params['id'];
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM sales WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (results.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Sale not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = results.first;
    final sale = {
      'id': row['id'].toString(),
      'stock_item_id': row['stock_item_id']?.toString(),
      'stock_type': row['stock_type'],
      'customer_id': row['customer_id']?.toString(),
      'customer_name': row['customer_name'],
      'magunia': row['magunia'],
      'price_per_bag': (row['price_per_bag'] as num).toDouble(),
      'payment_type': row['payment_type'],
      'amount_paid': (row['amount_paid'] as num).toDouble(),
      'date': row['date'].toIso8601String(),
    };

    return Response.ok(
      jsonEncode(sale),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _createSale(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final stockItemId = data['stock_item_id'] as String?;
    final stockType = data['stock_type'] as String?;
    final customerId = data['customer_id'] as String?;
    final customerName = data['customer_name'] as String?;
    final magunia = data['magunia'] as int?;
    final pricePerBag = (data['price_per_bag'] as num?)?.toDouble();
    final paymentType = data['payment_type'] as String?;
    final amountPaid = (data['amount_paid'] as num?)?.toDouble() ?? 0;

    if (stockItemId == null || stockType == null || customerName == null ||
        magunia == null || pricePerBag == null || paymentType == null) {
      return Response(400,
          body: jsonEncode({'error': 'Missing required fields'}),
          headers: {'Content-Type': 'application/json'});
    }

    // Validate payment_type
    if (!['cash', 'mobile', 'credit', 'partial'].contains(paymentType)) {
      return Response(400,
          body: jsonEncode({'error': 'Invalid payment_type'}),
          headers: {'Content-Type': 'application/json'});
    }

    final conn = await Database.getConnection();

    // Check stock availability
    final stockResult = await conn.mappedResultsQuery(
      'SELECT * FROM stock_items WHERE id = @id',
      substitutionValues: {'id': stockItemId},
    );

    if (stockResult.isEmpty) {
      return Response(404,
          body: jsonEncode({'error': 'Stock item not found'}),
          headers: {'Content-Type': 'application/json'});
    }

    final stockRow = stockResult.first;
    final remaining = (stockRow['total_magunia'] as int) - (stockRow['sold_magunia'] as int);
    if (magunia > remaining) {
      return Response(400,
          body: jsonEncode({'error': 'Insufficient stock. Remaining: $remaining'}),
          headers: {'Content-Type': 'application/json'});
    }

    // Use transaction to ensure atomicity
    await conn.execute('BEGIN');

    try {
      // Update stock
      await conn.execute(
        '''UPDATE stock_items SET sold_magunia = sold_magunia + @magunia WHERE id = @id''',
        substitutionValues: {'magunia': magunia, 'id': stockItemId},
      );

      // Create sale
      final results = await conn.mappedResultsQuery(
        '''INSERT INTO sales (stock_item_id, stock_type, customer_id, customer_name, magunia, price_per_bag, payment_type, amount_paid)
           VALUES (@stockItemId, @stockType, @customerId, @customerName, @magunia, @pricePerBag, @paymentType, @amountPaid)
           RETURNING *''',
        substitutionValues: {
          'stockItemId': stockItemId,
          'stockType': stockType,
          'customerId': customerId,
          'customerName': customerName,
          'magunia': magunia,
          'pricePerBag': pricePerBag,
          'paymentType': paymentType,
          'amountPaid': amountPaid,
        },
      );

      await conn.execute('COMMIT');

      final row = results.first;
      final sale = {
        'id': row['id'].toString(),
        'stock_item_id': row['stock_item_id']?.toString(),
        'stock_type': row['stock_type'],
        'customer_id': row['customer_id']?.toString(),
        'customer_name': row['customer_name'],
        'magunia': row['magunia'],
        'price_per_bag': (row['price_per_bag'] as num).toDouble(),
        'payment_type': row['payment_type'],
        'amount_paid': (row['amount_paid'] as num).toDouble(),
        'date': row['date'].toIso8601String(),
      };

      return Response.ok(
        jsonEncode(sale),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      await conn.execute('ROLLBACK');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create sale: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
