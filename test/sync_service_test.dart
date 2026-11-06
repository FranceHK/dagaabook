import 'dart:convert';

import 'package:dagaabook/services/local_store.dart';
import 'package:dagaabook/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _sale(String id, int magunia) => {'id': id, 'stock_item_id': 'st1', 'magunia': magunia};

http.Response _snapshot(Map<String, dynamic> data) =>
    http.Response(jsonEncode({'data': data, 'updatedAt': '2026-11-06T10:00:00Z'}), 200);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sync sends every collection with the key', () async {
    await LocalStore.saveList(LocalStore.customersKey, [
      {'id': 'c1', 'name': 'Asha'}
    ]);
    await LocalStore.saveMap(LocalStore.profileKey, {'ownerName': 'Juma'});

    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return _snapshot({});
    });

    await SyncService(client: client).sync('https://example.test/', 'secret-key-123', preferLocal: true);

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

  test('owner keeps own edits and gains the helper sales', () async {
    await LocalStore.saveList(LocalStore.customersKey, [
      {'id': 'c1', 'name': 'Asha (new name)'}
    ]);
    await LocalStore.saveList(LocalStore.stockKey, [
      {'id': 'st1', 'sold_magunia': 3}
    ]);
    await LocalStore.saveList(LocalStore.salesKey, [_sale('owner', 3)]);

    final client = MockClient((_) async => _snapshot({
          'customers': [
            {'id': 'c1', 'name': 'Asha'},
            {'id': 'c2', 'name': 'Added by helper'},
          ],
          'stock': [
            {'id': 'st1', 'sold_magunia': 3}
          ],
          'sales': [_sale('owner', 3), _sale('helper', 2)],
        }));

    await SyncService(client: client).sync('https://example.test', 'secret-key-123', preferLocal: true);

    final customers = await LocalStore.loadList(LocalStore.customersKey, (j) => j);
    expect(customers.map((c) => c['name']), ['Asha (new name)', 'Added by helper']);
    final stock = await LocalStore.loadList(LocalStore.stockKey, (j) => j);
    expect(stock.single['sold_magunia'], 5);
  });

  test('helper takes the owner version and keeps unsent sales', () async {
    await LocalStore.saveList(LocalStore.customersKey, [
      {'id': 'c1', 'name': 'Old name'}
    ]);
    await LocalStore.saveList(LocalStore.salesKey, [_sale('not_sent_yet', 1)]);

    final client = MockClient((_) async => _snapshot({
          'customers': [
            {'id': 'c1', 'name': 'Renamed by owner'}
          ],
          'stock': [
            {'id': 'st1', 'sold_magunia': 0, 'purchase_price_per_bag': 0}
          ],
          'sales': [],
          'profile': [
            {'id': 'main', 'ownerName': 'Juma'}
          ],
        }));

    await SyncService(client: client).sync('https://example.test', 'helper.x.y', preferLocal: false);

    expect((await LocalStore.loadList(LocalStore.customersKey, (j) => j)).single['name'], 'Renamed by owner');
    expect((await LocalStore.loadList(LocalStore.salesKey, (j) => j)).single['id'], 'not_sent_yet');
    expect((await LocalStore.loadList(LocalStore.stockKey, (j) => j)).single['sold_magunia'], 1);
    expect(await LocalStore.loadMap(LocalStore.profileKey), {'ownerName': 'Juma'});
  });

  test('helper login returns the session', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/helper/login');
      expect(jsonDecode(request.body), {'phone': '0711', 'password': 'pass'});
      return http.Response(jsonEncode({'id': 'helper_1', 'name': 'Neema', 'token': 'helper.helper_1.t'}), 200);
    });
    final session = await SyncService(client: client).helperLogin('https://example.test', '0711', 'pass');
    expect(session.name, 'Neema');
    expect(session.token, 'helper.helper_1.t');
  });

  test('server answers become readable error codes', () async {
    Future<String> codeFor(int status) async {
      final client = MockClient((_) async => http.Response('{}', status));
      try {
        await SyncService(client: client).sync('https://example.test', 'secret-key-123', preferLocal: true);
        return 'none';
      } on SyncException catch (e) {
        return e.code;
      }
    }

    expect(await codeFor(401), 'unauthorized');
    expect(await codeFor(403), 'server_403');
    expect(await codeFor(500), 'server_500');
  });

  test('newer owner login wins on either side', () {
    final older = {'id': 'owner', 'phone': 'old', 'updated_at': '2026-01-01T00:00:00.000Z'};
    final newer = {'id': 'owner', 'phone': 'new', 'updated_at': '2026-11-06T10:00:00.000Z'};
    expect(SyncService.mergeById([older], [newer], preferLocal: true).single['phone'], 'new');
    expect(SyncService.mergeById([newer], [older], preferLocal: false).single['phone'], 'new');
  });
}
