import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import '../lib/db.dart';
import '../lib/routes/auth.dart';
import '../lib/routes/customers.dart';
import '../lib/routes/stock.dart';
import '../lib/routes/sales.dart';
import '../lib/routes/payments.dart';

void main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final corsMiddleware = (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        });
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
    };
  };

  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware);

  final router = Router()
    ..mount('/api/auth', AuthRoutes().handler)
    ..mount('/api/customers', CustomerRoutes().handler)
    ..mount('/api/stock', StockRoutes().handler)
    ..mount('/api/sales', SalesRoutes().handler)
    ..mount('/api/payments', PaymentsRoutes().handler)
    ..get('/health', (Request request) => Response.ok('OK'));

  final handler = pipeline.addHandler(router.call);

  try {
    await Database.getConnection();
    print('Database connection successful!');

    final server = await io.serve(handler, InternetAddress.anyIPv4, port);
    print('DagaaBook API server running on http://${server.address.host}:${server.port}');
  } catch (e) {
    print('Failed to start server: $e');
    exit(1);
  }
}
