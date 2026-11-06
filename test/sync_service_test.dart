import 'dart:convert';

import 'package:dagaabook/services/local_store.dart';
import 'package:dagaabook/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('upload sends every collection with the key', () async {
    await LocalStore.saveList(LocalStore.customersKey, [
      {'id': 'c1', 'name': 'Asha'}
    ]);
    await LocalStore.saveMap(LocalStore.profileKey, {'ownerName': 'Juma'});

    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return http.Response(jsonEncode({'ok': true, 'updatedAt': '2026-11-06T10:00:00Z'}), 200);
    });

    await SyncService(client: client).upload('https://example.test/', 'secret-key-123');

    expect(sent.url.toString(), 'https://example.test/sync');
    expect(sent.headers['authorization'], 'Bearer secret-key-123');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['customers'], [
      {'id': 'c1', 'name': 'Asha'}
    ]);
    expect(body['profile'], [
      {'ownerName': 'Juma', 'id': 'main'}
    ]);
    expect(body['sales'], isEmpty);
  });

  test('restore writes the backup over local data', () async {
    await LocalStore.saveList(LocalStore.stockKey, [
      {'id': 'old'}
    ]);
    final client = MockClient((_) async => http.Response(
          jsonEncode({
            'data': {
              'customers': [],
              'payments': [],
              'stock': [
                {'id': 'st1', 'type': 'Dagaa'}
              ],
              'sales': [],
              'profile': [
                {'id': 'main', 'ownerName': 'Juma'}
              ],
            },
            'updatedAt': '2026-11-06T10:00:00Z',
          }),
          200,
        ));

    await SyncService(client: client).restore('https://example.test', 'secret-key-123');

    expect(await LocalStore.loadList(LocalStore.stockKey, (j) => j), [
      {'id': 'st1', 'type': 'Dagaa'}
    ]);
    expect(await LocalStore.loadMap(LocalStore.profileKey), {'ownerName': 'Juma'});
  });

  test('server answers become readable error codes', () async {
    Future<String> codeFor(int status) async {
      final client = MockClient((_) async => http.Response('{}', status));
      try {
        await SyncService(client: client).upload('https://example.test', 'secret-key-123');
        return 'none';
      } on SyncException catch (e) {
        return e.code;
      }
    }

    expect(await codeFor(401), 'unauthorized');
    expect(await codeFor(409), 'empty');
    expect(await codeFor(500), 'server_500');
  });
}
