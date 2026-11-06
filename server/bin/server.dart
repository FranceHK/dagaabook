import 'dart:io';

import 'package:dagaabook_server/api.dart';
import 'package:dagaabook_server/store.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Reads DATABASE_URL, SYNC_KEY and PORT from the environment.
/// Without DATABASE_URL the data is kept in memory (for local testing only).
Future<void> main() async {
  final env = Platform.environment;
  final syncKey = env['SYNC_KEY'] ?? '';
  if (syncKey.length < 12) {
    stderr.writeln('SYNC_KEY must be set and at least 12 characters long.');
    exit(1);
  }

  final databaseUrl = env['DATABASE_URL'];
  final SyncStore store;
  if (databaseUrl == null || databaseUrl.isEmpty) {
    stdout.writeln('DATABASE_URL not set, keeping data in memory.');
    store = MemoryStore();
  } else {
    store = await PostgresStore.connect(databaseUrl);
    stdout.writeln('Connected to Postgres.');
  }

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(buildHandler(store, syncKey));
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('DagaaBook sync server listening on port ${server.port}');
}
