import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'store.dart';

/// Builds the HTTP handler. Every route except /health needs
/// `Authorization: Bearer <syncKey>`.
Handler buildHandler(SyncStore store, String syncKey) {
  final router = Router()
    ..get('/health', (Request _) => _json({'ok': true}))
    ..get('/snapshot', (Request _) async {
      return _json({
        'data': await store.loadAll(),
        'updatedAt': (await store.lastUpdated())?.toIso8601String(),
      });
    })
    ..post('/sync', (Request request) async {
      final Object? body;
      try {
        body = jsonDecode(await request.readAsString());
      } on FormatException {
        return _json({'error': 'invalid_json'}, status: 400);
      }
      if (body is! Map<String, dynamic>) return _json({'error': 'invalid_body'}, status: 400);

      final snapshot = <String, List<Map<String, dynamic>>>{};
      for (final collection in collections) {
        final list = body[collection];
        if (list == null) continue;
        if (list is! List || list.any((r) => r is! Map || r['id'] == null)) {
          return _json({'error': 'invalid_$collection'}, status: 400);
        }
        snapshot[collection] = list.cast<Map<String, dynamic>>();
      }

      // An empty upload would wipe the backup, so it has to be asked for.
      final isEmpty = snapshot.values.every((l) => l.isEmpty);
      if (isEmpty && request.url.queryParameters['force'] != '1') {
        return _json({'error': 'empty_snapshot'}, status: 409);
      }

      await store.replaceAll(snapshot);
      return _json({
        'ok': true,
        'counts': {for (final e in snapshot.entries) e.key: e.value.length},
        'updatedAt': (await store.lastUpdated())?.toIso8601String(),
      });
    });

  return const Pipeline()
      .addMiddleware(_cors())
      .addMiddleware(_auth(syncKey))
      .addHandler(router.call);
}

Response _json(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Middleware _auth(String syncKey) => (inner) => (request) {
      if (request.url.path == 'health' || request.method == 'OPTIONS') return inner(request);
      final header = request.headers['authorization'] ?? '';
      final token = header.startsWith('Bearer ') ? header.substring(7) : '';
      if (!_sameText(token, syncKey)) return _json({'error': 'unauthorized'}, status: 401);
      return inner(request);
    };

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'authorization, content-type',
};

Middleware _cors() => (inner) => (request) async {
      if (request.method == 'OPTIONS') return Response.ok('', headers: _corsHeaders);
      final response = await inner(request);
      return response.change(headers: _corsHeaders);
    };

/// Compares in constant time so the key can't be guessed from timing.
bool _sameText(String a, String b) {
  if (a.length != b.length || b.isEmpty) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
