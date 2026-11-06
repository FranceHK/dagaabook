import 'dart:convert';

import 'package:dagaabook_server/api.dart';
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

void main() {
  late Handler handler;

  setUp(() => handler = buildHandler(MemoryStore(), key));

  test('health needs no key', () async {
    final r = await handler(_req('GET', '/health', token: null));
    expect(r.statusCode, 200);
  });

  test('wrong key is rejected', () async {
    expect((await handler(_req('GET', '/snapshot', token: 'nope'))).statusCode, 401);
    expect((await handler(_req('GET', '/snapshot', token: null))).statusCode, 401);
  });

  test('sync then snapshot returns the same records', () async {
    final r = await handler(_req('POST', '/sync', body: {
      'customers': [
        {'id': 'c1', 'name': 'Asha'},
      ],
      'sales': [
        {'id': 's1', 'magunia': 3},
      ],
      'profile': [
        {'id': 'main', 'ownerName': 'Juma'},
      ],
    }));
    expect(r.statusCode, 200);
    expect((await _body(r))['counts'], {'customers': 1, 'sales': 1, 'profile': 1});

    final snap = await _body(await handler(_req('GET', '/snapshot')));
    final data = snap['data'] as Map<String, dynamic>;
    expect(data['customers'], [
      {'id': 'c1', 'name': 'Asha'}
    ]);
    expect(data['payments'], isEmpty);
    expect(snap['updatedAt'], isNotNull);
  });

  test('empty upload needs force', () async {
    expect((await handler(_req('POST', '/sync', body: {'customers': []}))).statusCode, 409);
    expect((await handler(_req('POST', '/sync?force=1', body: {'customers': []}))).statusCode, 200);
  });

  test('records without id are rejected', () async {
    final r = await handler(_req('POST', '/sync', body: {
      'stock': [
        {'type': 'dagaa'}
      ],
    }));
    expect(r.statusCode, 400);
  });
}
