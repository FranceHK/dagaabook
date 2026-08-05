import 'dart:io';
import 'package:postgres/postgres.dart';

class Database {
  static PostgreSQLConnection? _connection;

  static Future<PostgreSQLConnection> getConnection() async {
    if (_connection != null && !_connection!.isClosed) {
      return _connection!;
    }

    final databaseUrl = Platform.environment['DATABASE_URL'];
    if (databaseUrl == null) {
      throw Exception('DATABASE_URL not set in environment');
    }

    final uri = Uri.parse(databaseUrl);
    final host = uri.host;
    final port = uri.port;
    final databaseName = uri.pathSegments.first;
    final username = uri.userInfo.split(':').first;
    final password = uri.userInfo.split(':').last;

    _connection = PostgreSQLConnection(
      host,
      port,
      databaseName,
      username: username,
      password: password,
      useSSL: true,
    );

    await _connection!.open();
    print('Connected to PostgreSQL at $host:$port/$databaseName');
    return _connection!;
  }

  static Future<void> close() async {
    if (_connection != null && !_connection!.isClosed) {
      await _connection!.close();
      print('Database connection closed');
    }
  }
}
