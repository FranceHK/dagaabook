import 'dart:convert';

import 'package:postgres/postgres.dart';

/// The collections the app backs up. `profile` holds a single record and
/// `helpers` holds the helper accounts the owner created.
const collections = ['customers', 'payments', 'stock', 'sales', 'profile', 'helpers'];

typedef Snapshot = Map<String, List<Map<String, dynamic>>>;

/// Where synced records are kept.
/// Records are never deleted: the app has no delete, so both phones' data
/// can be merged by id.
abstract class SyncStore {
  /// Saves every record, replacing ones with the same id (owner uploads).
  Future<void> upsertAll(Snapshot snapshot);

  /// Saves only records whose id is new; existing ones are left alone
  /// (helper uploads, so a helper can add but never change).
  Future<void> insertNew(String collection, List<Map<String, dynamic>> records);

  Future<Snapshot> loadAll();
  Future<DateTime?> lastUpdated();
}

/// Keeps records in memory. Used by tests and for local runs without a database.
class MemoryStore implements SyncStore {
  Snapshot _data = {for (final c in collections) c: []};
  DateTime? _updated;

  @override
  Future<void> upsertAll(Snapshot snapshot) async {
    for (final entry in snapshot.entries) {
      final list = _data[entry.key]!;
      for (final record in entry.value) {
        final i = list.indexWhere((r) => r['id'] == record['id']);
        i == -1 ? list.add(record) : list[i] = record;
      }
    }
    _updated = DateTime.now().toUtc();
  }

  @override
  Future<void> insertNew(String collection, List<Map<String, dynamic>> records) async {
    final list = _data[collection]!;
    for (final record in records) {
      if (!list.any((r) => r['id'] == record['id'])) list.add(record);
    }
    _updated = DateTime.now().toUtc();
  }

  @override
  Future<Snapshot> loadAll() async => {for (final c in collections) c: List.of(_data[c]!)};

  @override
  Future<DateTime?> lastUpdated() async => _updated;
}

/// Keeps records in Postgres (Neon) in one `records` table.
class PostgresStore implements SyncStore {
  PostgresStore._(this._pool);

  final Pool _pool;

  /// Opens a pool from a `postgresql://user:pass@host/db?sslmode=require` URL.
  static Future<PostgresStore> connect(String databaseUrl) async {
    final uri = Uri.parse(databaseUrl);
    final userInfo = uri.userInfo.split(':');
    final endpoint = Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres',
      username: Uri.decodeComponent(userInfo.first),
      password: userInfo.length > 1 ? Uri.decodeComponent(userInfo.sublist(1).join(':')) : null,
    );
    final sslMode = uri.queryParameters['sslmode'] == 'disable' ? SslMode.disable : SslMode.require;
    final pool = Pool.withEndpoints(
      [endpoint],
      settings: PoolSettings(maxConnectionCount: 4, sslMode: sslMode),
    );
    final store = PostgresStore._(pool);
    await store._createTable();
    return store;
  }

  Future<void> _createTable() async {
    await _pool.execute('''
      CREATE TABLE IF NOT EXISTS records (
        collection TEXT NOT NULL,
        id TEXT NOT NULL,
        data JSONB NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (collection, id)
      )
    ''');
  }

  @override
  Future<void> upsertAll(Snapshot snapshot) async {
    await _pool.runTx((tx) async {
      for (final entry in snapshot.entries) {
        for (final record in entry.value) {
          await tx.execute(
            Sql.named('INSERT INTO records (collection, id, data) VALUES (@c, @id, CAST(@data AS JSONB)) '
                'ON CONFLICT (collection, id) DO UPDATE SET data = EXCLUDED.data, updated_at = now() '
                'WHERE records.data IS DISTINCT FROM EXCLUDED.data'),
            parameters: {'c': entry.key, 'id': '${record['id']}', 'data': jsonEncode(record)},
          );
        }
      }
    });
  }

  @override
  Future<void> insertNew(String collection, List<Map<String, dynamic>> records) async {
    await _pool.runTx((tx) async {
      for (final record in records) {
        await tx.execute(
          Sql.named('INSERT INTO records (collection, id, data) VALUES (@c, @id, CAST(@data AS JSONB)) '
              'ON CONFLICT (collection, id) DO NOTHING'),
          parameters: {'c': collection, 'id': '${record['id']}', 'data': jsonEncode(record)},
        );
      }
    });
  }

  @override
  Future<Snapshot> loadAll() async {
    final rows = await _pool.execute('SELECT collection, data::text FROM records');
    final result = <String, List<Map<String, dynamic>>>{for (final c in collections) c: []};
    for (final row in rows) {
      final collection = row[0] as String;
      if (!result.containsKey(collection)) continue;
      result[collection]!.add(jsonDecode(row[1] as String) as Map<String, dynamic>);
    }
    return result;
  }

  @override
  Future<DateTime?> lastUpdated() async {
    final rows = await _pool.execute('SELECT max(updated_at) FROM records');
    return rows.first[0] as DateTime?;
  }
}
