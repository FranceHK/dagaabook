import 'dart:convert';

import 'package:dagaabook_server/api.dart';
import 'package:dagaabook_server/passwords.dart';
import 'package:dagaabook_server/store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const key = 'test-sync-key-123';

Request _req(String method, String path, {Object? body, String? token = key}) => Request(
      method,
      Uri.parse('http://localhost$path'),
      body: body == null ? null : jsonEncode(body),
      headers: {if (token != null) 'authorization': 'Bearer $token'},
    );

Future<Map<String, dynamic>> _body(Response r) async =>
    jsonDecode(await r.readAsString()) as Map<String, dynamic>;

Map<String, dynamic> _helper({bool active = true}) => {
      'id': 'helper_1',
      'name': 'Neema',
      'phone': '0711 111 111',
      'salt': 'salt1',
      'password_hash': hashPassword('pass1234', 'salt1'),
      'active': active,
    };

Map<String, dynamic> _sale(String id, {String type = 'cash', num paid = 60000, num price = 30000}) => {
      'id': id,
      'stock_item_id': 'st1',
      'magunia': 2,
      'price_per_bag': price,
      'payment_type': type,
      'amount_paid': paid,
    };

void main() {
  late Handler handler;

  setUp(() => handler = buildHandler(MemoryStore(), key));

  Future<String> helperLogin() async {
    final r = await handler(_req('POST', '/helper/login', token: null, body: {'phone': '0711111111', 'password': 'pass1234'}));
    expect(r.statusCode, 200);
    return (await _body(r))['token'] as String;
  }

  Future<void> ownerSeed({bool helperActive = true}) async {
    final r = await handler(_req('POST', '/sync', body: {
      'stock': [
        {'id': 'st1', 'selling_price_per_bag': 30000, 'purchase_price_per_bag': 20000}
      ],
      'payments': [
        {'id': 'p1', 'amount': 5000}
      ],
      'sales': [_sale('owner_credit', type: 'credit', paid: 0)],
      'helpers': [_helper(active: helperActive)],
    }));
    expect(r.statusCode, 200);
  }

  test('health needs no key', () async {
    final r = await handler(_req('GET', '/health', token: null));
    expect(r.statusCode, 200);
  });

  test('wrong key is rejected', () async {
    expect((await handler(_req('GET', '/snapshot', token: 'nope'))).statusCode, 401);
    expect((await handler(_req('GET', '/snapshot', token: null))).statusCode, 401);
    expect((await handler(_req('GET', '/snapshot', token: 'helper.helper_1.fake'))).statusCode, 401);
  });

  test('owner uploads are merged, not replaced', () async {
    await handler(_req('POST', '/sync', body: {
      'customers': [
        {'id': 'c1', 'name': 'Asha'}
      ],
    }));
    final r = await handler(_req('POST', '/sync', body: {
      'customers': [
        {'id': 'c1', 'name': 'Asha M'},
        {'id': 'c2', 'name': 'Baraka'},
      ],
    }));
    expect(r.statusCode, 200);
    final data = (await _body(r))['data'] as Map<String, dynamic>;
    expect(data['customers'], [
      {'id': 'c1', 'name': 'Asha M'},
      {'id': 'c2', 'name': 'Baraka'},
    ]);
  });

  test('records without id are rejected', () async {
    final r = await handler(_req('POST', '/sync', body: {
      'stock': [
        {'type': 'dagaa'}
      ],
    }));
    expect(r.statusCode, 400);
  });

  test('helper logs in with the password the owner set', () async {
    await ownerSeed();
    final bad = await handler(_req('POST', '/helper/login', token: null, body: {'phone': '0711111111', 'password': 'nope'}));
    expect(bad.statusCode, 401);
    expect(await helperLogin(), startsWith('helper.helper_1.'));
  });

  test('stopped helper cannot log in', () async {
    await ownerSeed(helperActive: false);
    final r = await handler(_req('POST', '/helper/login', token: null, body: {'phone': '0711111111', 'password': 'pass1234'}));
    expect(r.statusCode, 401);
  });

  test('helper sees no payments, helpers or buying prices', () async {
    await ownerSeed();
    final token = await helperLogin();
    final data = (await _body(await handler(_req('GET', '/snapshot', token: token))))['data'] as Map<String, dynamic>;
    expect(data.keys, unorderedEquals(['customers', 'stock', 'sales', 'profile']));
    expect((data['stock'] as List).first['purchase_price_per_bag'], 0);
  });

  test('helper can add cash sales and customers but not change anything', () async {
    await ownerSeed();
    final token = await helperLogin();
    final r = await handler(_req('POST', '/sync', token: token, body: {
      'customers': [
        {'id': 'c9', 'name': 'Mteja Mpya'}
      ],
      'sales': [_sale('owner_credit', type: 'credit', paid: 0), _sale('helper_sale')],
      'stock': [
        {'id': 'st1', 'selling_price_per_bag': 1}
      ],
      'payments': [
        {'id': 'p2', 'amount': 1}
      ],
    }));
    expect(r.statusCode, 200);

    final owner = (await _body(await handler(_req('GET', '/snapshot'))))['data'] as Map<String, dynamic>;
    expect((owner['stock'] as List).first['selling_price_per_bag'], 30000);
    expect(owner['payments'], hasLength(1));
    expect((owner['customers'] as List).map((c) => c['id']), ['c9']);
    final sale = (owner['sales'] as List).firstWhere((s) => s['id'] == 'helper_sale');
    expect(sale['sold_by'], 'helper_1');
  });

  test('helper cannot sell on credit or at another price', () async {
    await ownerSeed();
    final token = await helperLogin();
    for (final sale in [
      _sale('s_credit', type: 'credit', paid: 0),
      _sale('s_cheap', price: 1000, paid: 2000),
      _sale('s_short', paid: 100),
    ]) {
      final r = await handler(_req('POST', '/sync', token: token, body: {
        'sales': [sale]
      }));
      expect(r.statusCode, 403, reason: sale['id'] as String);
    }
  });

  test('resetting the helper password signs the old phone out', () async {
    await ownerSeed();
    final token = await helperLogin();
    await handler(_req('POST', '/sync', body: {
      'helpers': [
        {..._helper(), 'password_hash': hashPassword('newpass99', 'salt1')}
      ],
    }));
    expect((await handler(_req('GET', '/snapshot', token: token))).statusCode, 401);
  });
}
