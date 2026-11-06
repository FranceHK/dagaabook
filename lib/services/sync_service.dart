import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_store.dart';

/// Thrown when the server can't be reached or answers with an error.
class SyncException implements Exception {
  final String code;
  const SyncException(this.code);

  @override
  String toString() => 'SyncException($code)';
}

/// Sends this phone's data to the DagaaBook sync server (which keeps it in
/// Neon Postgres) and brings it back on restore. The server address and key
/// are typed in Settings; nothing secret is built into the app.
class SyncService {
  SyncService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _listKeys = {
    'customers': LocalStore.customersKey,
    'payments': LocalStore.paymentsKey,
    'stock': LocalStore.stockKey,
    'sales': LocalStore.salesKey,
  };
  static const _profileId = 'main';
  static const _timeout = Duration(seconds: 60);

  /// Everything the server stores, read straight from this phone.
  static Future<Map<String, List<Map<String, dynamic>>>> buildSnapshot() async {
    final snapshot = <String, List<Map<String, dynamic>>>{};
    for (final entry in _listKeys.entries) {
      snapshot[entry.key] = await LocalStore.loadList(entry.value, (json) => json);
    }
    final profile = await LocalStore.loadMap(LocalStore.profileKey);
    snapshot['profile'] = [if (profile != null) {...profile, 'id': _profileId}];
    return snapshot;
  }

  /// Replaces this phone's data with a snapshot from the server.
  static Future<void> applySnapshot(Map<String, dynamic> data) async {
    for (final entry in _listKeys.entries) {
      final list = (data[entry.key] as List? ?? const []).cast<Map<String, dynamic>>();
      await LocalStore.saveList(entry.value, list, notify: false);
    }
    final profiles = (data['profile'] as List? ?? const []).cast<Map<String, dynamic>>();
    if (profiles.isNotEmpty) {
      await LocalStore.saveMap(LocalStore.profileKey, Map.of(profiles.first)..remove('id'), notify: false);
    }
  }

  Uri _uri(String baseUrl, String path) {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  Map<String, String> _headers(String key) => {
        'authorization': 'Bearer ${key.trim()}',
        'content-type': 'application/json',
      };

  /// Uploads all data. Returns the server's save time.
  Future<DateTime> upload(String baseUrl, String key) async {
    final body = jsonEncode(await buildSnapshot());
    final response = await _send(() => _client.post(_uri(baseUrl, '/sync'), headers: _headers(key), body: body));
    return _updatedAt(response);
  }

  /// Downloads the backup and writes it over this phone's data.
  Future<DateTime> restore(String baseUrl, String key) async {
    final response = await _send(() => _client.get(_uri(baseUrl, '/snapshot'), headers: _headers(key)));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    await applySnapshot(json['data'] as Map<String, dynamic>);
    return _updatedAt(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } catch (_) {
      throw const SyncException('offline');
    }
    if (response.statusCode == 401) throw const SyncException('unauthorized');
    if (response.statusCode == 409) throw const SyncException('empty');
    if (response.statusCode != 200) throw SyncException('server_${response.statusCode}');
    return response;
  }

  DateTime _updatedAt(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now();
  }
}
