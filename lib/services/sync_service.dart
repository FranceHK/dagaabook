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

/// What /helper/login returns.
class HelperSession {
  final String id;
  final String name;
  final String token;
  const HelperSession({required this.id, required this.name, required this.token});
}

/// Exchanges data with the DagaaBook sync server (which keeps it in Neon
/// Postgres). Each sync sends this phone's records and merges back what the
/// other phone (owner or helper) added. The server address and key are typed
/// in the app; nothing secret is built into it.
class SyncService {
  SyncService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _listKeys = {
    'customers': LocalStore.customersKey,
    'payments': LocalStore.paymentsKey,
    'stock': LocalStore.stockKey,
    'sales': LocalStore.salesKey,
    'helpers': LocalStore.helpersKey,
    'account': LocalStore.accountKey,
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

  /// Joins two lists of records by id. Records are never deleted, so the
  /// result holds every id from both. When both have the same id, the newer
  /// `updated_at` wins if both have one (the owner login); otherwise
  /// [preferLocal] decides (the owner's phone wins, a helper's loses).
  static List<Map<String, dynamic>> mergeById(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> server, {
    required bool preferLocal,
  }) {
    final byId = <String, Map<String, dynamic>>{for (final r in server) '${r['id']}': r};
    for (final r in local) {
      final id = '${r['id']}';
      final other = byId[id];
      if (other == null) {
        byId[id] = r;
        continue;
      }
      final mine = r['updated_at'];
      final theirs = other['updated_at'];
      final localWins = mine is String && theirs is String ? mine.compareTo(theirs) >= 0 : preferLocal;
      if (localWins) byId[id] = r;
    }
    return byId.values.toList();
  }

  /// Writes the server's data into this phone, merged with what is here.
  static Future<void> applySnapshot(Map<String, dynamic> data, {required bool preferLocal}) async {
    final merged = <String, List<Map<String, dynamic>>>{};
    for (final entry in _listKeys.entries) {
      final local = await LocalStore.loadList(entry.value, (json) => json);
      if (!data.containsKey(entry.key)) {
        merged[entry.key] = local;
        continue;
      }
      final server = (data[entry.key] as List).cast<Map<String, dynamic>>();
      merged[entry.key] = mergeById(local, server, preferLocal: preferLocal);
    }

    // Sales from both phones decide how many boxes are gone from each batch.
    final soldByStock = <String, int>{};
    for (final sale in merged['sales']!) {
      final id = '${sale['stock_item_id']}';
      soldByStock[id] = (soldByStock[id] ?? 0) + ((sale['magunia'] as num?)?.toInt() ?? 0);
    }
    merged['stock'] = [
      for (final s in merged['stock']!)
        {...s, 'sold_magunia': _max((s['sold_magunia'] as num?)?.toInt() ?? 0, soldByStock['${s['id']}'] ?? 0)},
    ];

    for (final entry in _listKeys.entries) {
      await LocalStore.saveList(entry.value, merged[entry.key]!, notify: false);
    }

    final profiles = (data['profile'] as List? ?? const []).cast<Map<String, dynamic>>();
    final hasLocalProfile = await LocalStore.loadMap(LocalStore.profileKey) != null;
    if (profiles.isNotEmpty && !(preferLocal && hasLocalProfile)) {
      await LocalStore.saveMap(LocalStore.profileKey, Map.of(profiles.first)..remove('id'), notify: false);
    }
  }

  static int _max(int a, int b) => a > b ? a : b;

  Uri _uri(String baseUrl, String path) {
    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path');
  }

  Map<String, String> _headers(String key) => {
        'authorization': 'Bearer ${key.trim()}',
        'content-type': 'application/json',
      };

  /// Sends this phone's data, then merges in the server's. Returns the
  /// server's save time.
  Future<DateTime> sync(String baseUrl, String key, {required bool preferLocal}) async {
    final body = jsonEncode(await buildSnapshot());
    final response = await _send(() => _client.post(_uri(baseUrl, '/sync'), headers: _headers(key), body: body));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    await applySnapshot(json['data'] as Map<String, dynamic>, preferLocal: preferLocal);
    return _updatedAt(json);
  }

  /// Checks a helper's phone and password with the server.
  Future<HelperSession> helperLogin(String baseUrl, String phone, String password) async {
    final response = await _send(() => _client.post(
          _uri(baseUrl, '/helper/login'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'phone': phone, 'password': password}),
        ));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return HelperSession(id: json['id'] as String, name: json['name'] as String? ?? '', token: json['token'] as String);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } catch (_) {
      throw const SyncException('offline');
    }
    if (response.statusCode == 401) throw const SyncException('unauthorized');
    if (response.statusCode != 200) throw SyncException('server_${response.statusCode}');
    return response;
  }

  DateTime _updatedAt(Map<String, dynamic> json) =>
      DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toLocal() ?? DateTime.now();
}
