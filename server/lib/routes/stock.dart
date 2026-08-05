import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db.dart';

class StockRoutes {
  Handler get handler {
    final router = Router()
      ..get('/api/stock', _getStock)
      ..get('/api/stock/<id>', _getStockById)
      ..post('/api/stock', _createStock);

    return router.call;
  }

  Future<Response> _getStock(Request request) async {
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM stock_items ORDER BY date_added DESC',
    );

    final stock = results.map((row) {
      return {
        'id': row['id'].toString(),
        'type': row['type'],
        'total_magunia': row['total_magunia'],
        'sold_magunia': row['sold_magunia'],
        'purchase_price_per_bag': (row['purchase_price_per_bag'] as num).toDouble(),
        'selling_price_per_bag': (row['selling_price_per_bag'] as num).toDouble(),
        'date_added': row['date_added'].toIso8601String(),
        'supplier': row['supplier'],
      };
    }).toList();

    return Response.ok(
      jsonEncode(stock),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getStockById(Request request) async {
    final id = request.params['id'];
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM stock_items WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (results.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Stock item not found'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final row = results.first;
    final item = {
      'id': row['id'].toString(),
      'type': row['type'],
      'total_magunia': row['total_magunia'],
      'sold_magunia': row['sold_magunia'],
      'purchase_price_per_bag': (row['purchase_price_per_bag'] as num).toDouble(),
      'selling_price_per_bag': (row['selling_price_per_bag'] as num).toDouble(),
      'date_added': row['date_added'].toIso8601String(),
      'supplier': row['supplier'],
    };

    return Response.ok(
      jsonEncode(item),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _createStock(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final type = data['type'] as String?;
    final totalMagunia = data['total_magunia'] as int?;
    final purchasePrice = (data['purchase_price_per_bag'] as num?)?.toDouble();
    final sellingPrice = (data['selling_price_per_bag'] as num?)?.toDouble();
    final supplier = data['supplier'] as String? ?? '';

    if (type == null || totalMagunia == null || purchasePrice == null || sellingPrice == null) {
      return Response(400,
          body: jsonEncode({'error': 'type, total_magunia, purchase_price_per_bag, selling_price_per_bag are required'}),
          headers: {'Content-Type': 'application/json'});
    }

    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      '''INSERT INTO stock_items (type, total_magunia, purchase_price_per_bag, selling_price_per_bag, supplier)
         VALUES (@type, @totalMagunia, @purchasePrice, @sellingPrice, @supplier)
         RETURNING *''',
      substitutionValues: {
        'type': type,
        'totalMagunia': totalMagunia,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'supplier': supplier,
      },
    );

    final row = results.first;
    final item = {
      'id': row['id'].toString(),
      'type': row['type'],
      'total_magunia': row['total_magunia'],
      'sold_magunia': row['sold_magunia'],
      'purchase_price_per_bag': (row['purchase_price_per_bag'] as num).toDouble(),
      'selling_price_per_bag': (row['selling_price_per_bag'] as num).toDouble(),
      'date_added': row['date_added'].toIso8601String(),
      'supplier': row['supplier'],
    };

    return Response.ok(
      jsonEncode(item),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
