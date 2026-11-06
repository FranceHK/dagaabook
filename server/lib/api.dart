import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'passwords.dart';
import 'store.dart';

/// Who made a request: the owner (holds the sync key) or one of the owner's
/// helpers (holds a token from /helper/login).
class Principal {
  final String? helperId;
  const Principal.owner() : helperId = null;
  const Principal.helper(String id) : helperId = id;
  bool get isOwner => helperId == null;
}

/// What a helper may download: no payments, no helper accounts and no
/// buying prices, so profit stays private.
const _helperCollections = ['customers', 'stock', 'sales', 'profile'];

/// Builds the HTTP handler. /health and /helper/login are open; everything
/// else needs `Authorization: Bearer <syncKey>` (owner) or
/// `Bearer helper.<id>.<token>` (helper).
Handler buildHandler(SyncStore store, String syncKey) {
  Future<Map<String, dynamic>?> findHelper(bool Function(Map<String, dynamic>) test) async {
    final helpers = (await store.loadAll())['helpers']!;
    for (final h in helpers) {
      if (h['active'] != false && test(h)) return h;
    }
    return null;
  }

  Future<Principal?> identify(Request request) async {
    final header = request.headers['authorization'] ?? '';
    final token = header.startsWith('Bearer ') ? header.substring(7) : '';
    if (sameText(token, syncKey)) return const Principal.owner();
    final parts = token.split('.');
    if (parts.length != 3 || parts[0] != 'helper') return null;
    final helper = await findHelper((h) => h['id'] == parts[1]);
    if (helper == null) return null;
    final expected = helperToken(syncKey, parts[1], '${helper['password_hash']}');
    return sameText(parts[2], expected) ? Principal.helper(parts[1]) : null;
  }

  Future<Response> snapshotFor(Principal who) async {
    final all = await store.loadAll();
    final updatedAt = (await store.lastUpdated())?.toIso8601String();
    if (who.isOwner) return _json({'data': all, 'updatedAt': updatedAt});
    return _json({
      'data': {
        for (final c in _helperCollections)
          c: c == 'stock' ? [for (final s in all[c]!) {...s, 'purchase_price_per_bag': 0}] : all[c],
      },
      'updatedAt': updatedAt,
    });
  }

  final router = Router()
    ..get('/health', (Request _) => _json({'ok': true}))
    ..post('/helper/login', (Request request) async {
      final body = await _readJson(request);
      if (body == null) return _json({'error': 'invalid_body'}, status: 400);
      final phone = _digits('${body['phone'] ?? ''}');
      final password = '${body['password'] ?? ''}';
      final helper = phone.isEmpty ? null : await findHelper((h) => _digits('${h['phone']}') == phone);
      if (helper == null || !sameText(hashPassword(password, '${helper['salt']}'), '${helper['password_hash']}')) {
        return _json({'error': 'wrong_login'}, status: 401);
      }
      final id = '${helper['id']}';
      return _json({
        'id': id,
        'name': helper['name'],
        'token': 'helper.$id.${helperToken(syncKey, id, '${helper['password_hash']}')}',
      });
    })
    ..get('/snapshot', (Request request) async {
      final who = await identify(request);
      if (who == null) return _unauthorized();
      return snapshotFor(who);
    })
    ..post('/sync', (Request request) async {
      final who = await identify(request);
      if (who == null) return _unauthorized();
      final body = await _readJson(request);
      if (body == null) return _json({'error': 'invalid_body'}, status: 400);

      final snapshot = <String, List<Map<String, dynamic>>>{};
      for (final collection in collections) {
        final list = body[collection];
        if (list == null) continue;
        if (list is! List || list.any((r) => r is! Map || r['id'] == null)) {
          return _json({'error': 'invalid_$collection'}, status: 400);
        }
        snapshot[collection] = list.cast<Map<String, dynamic>>();
      }

      if (who.isOwner) {
        await store.upsertAll(snapshot);
      } else {
        final existing = await store.loadAll();
        final stock = {for (final s in existing['stock']!) s['id']: s};
        final knownSales = {for (final s in existing['sales']!) s['id']};
        final sales = <Map<String, dynamic>>[];
        for (final sale in snapshot['sales'] ?? const <Map<String, dynamic>>[]) {
          // Sales already on the server (e.g. the owner's) were downloaded, not made here.
          if (knownSales.contains(sale['id'])) continue;
          if (!_isValidHelperSale(sale, stock[sale['stock_item_id']])) {
            return _json({'error': 'helper_cash_only'}, status: 403);
          }
          sales.add({...sale, 'sold_by': who.helperId});
        }
        await store.insertNew('customers', snapshot['customers'] ?? const []);
        await store.insertNew('sales', sales);
      }
      return snapshotFor(who);
    });

  return const Pipeline().addMiddleware(_cors()).addHandler(router.call);
}

/// Helpers can only sell for cash, in full, at the owner's selling price.
bool _isValidHelperSale(Map<String, dynamic> sale, Map<String, dynamic>? stock) {
  if (stock == null || sale['payment_type'] != 'cash') return false;
  final magunia = sale['magunia'];
  final price = sale['price_per_bag'];
  final paid = sale['amount_paid'];
  if (magunia is! int || magunia <= 0 || price is! num || paid is! num) return false;
  if ((price - (stock['selling_price_per_bag'] as num)).abs() > 0.01) return false;
  return (paid - magunia * price).abs() < 0.01;
}

String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

Future<Map<String, dynamic>?> _readJson(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());
    return body is Map<String, dynamic> ? body : null;
  } on FormatException {
    return null;
  }
}

Response _unauthorized() => _json({'error': 'unauthorized'}, status: 401);

Response _json(Object body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

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
