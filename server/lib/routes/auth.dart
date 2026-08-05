import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../db.dart';

class AuthRoutes {
  Handler get handler {
    final router = Router()
      ..post('/api/auth/register', _register)
      ..post('/api/auth/login', _login)
      ..get('/api/auth/user/<id>', _getUser);

    return router.call;
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password:$salt');
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  bool _verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final hash = _hashPassword(password, salt);
    return hash == storedHash;
  }

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  Future<Response> _register(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final firstName = (data['first_name'] as String?)?.trim() ?? '';
    final lastName = (data['last_name'] as String?)?.trim() ?? '';
    final email = (data['email'] as String?)?.trim() ?? '';
    final phone = (data['phone'] as String?)?.trim();
    final password = data['password'] as String?;

    if (phone == null || phone.isEmpty || password == null || password.length < 4) {
      return Response(400,
          body: jsonEncode({'error': 'Nambari ya simu na password ni lazima (min 4 herufi)'}),
          headers: {'Content-Type': 'application/json'});
    }

    if (firstName.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Jina la kwanza ni lazima'}),
          headers: {'Content-Type': 'application/json'});
    }

    final conn = await Database.getConnection();

    final existing = await conn.mappedResultsQuery(
      'SELECT id FROM users WHERE phone = @phone',
      substitutionValues: {'phone': phone},
    );

    if (existing.isNotEmpty) {
      return Response(409,
          body: jsonEncode({'error': 'Nambari ya simu tayari imesajiliwa'}),
          headers: {'Content-Type': 'application/json'});
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);

    final results = await conn.mappedResultsQuery(
      '''INSERT INTO users (first_name, last_name, email, phone, password_hash)
         VALUES (@firstName, @lastName, @email, @phone, @passwordHash)
         RETURNING id, first_name, last_name, email, phone, business_name, location, created_at''',
      substitutionValues: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'passwordHash': passwordHash,
      },
    );

    final row = results.first;
    final user = _rowToUser(row);

    return Response.ok(
      jsonEncode({'message': 'Usajili umefanikiwa', 'user': user}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _login(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    final phone = (data['phone'] as String?)?.trim();
    final password = data['password'] as String?;

    if (phone == null || phone.isEmpty || password == null || password.isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Nambari ya simu na password ni lazima'}),
          headers: {'Content-Type': 'application/json'});
    }

    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT * FROM users WHERE phone = @phone',
      substitutionValues: {'phone': phone},
    );

    if (results.isEmpty) {
      return Response(401,
          body: jsonEncode({'error': 'Nambari ya simu au password si sahihi'}),
          headers: {'Content-Type': 'application/json'});
    }

    final row = results.first;
    final storedHash = row['password_hash'] as String;

    if (!_verifyPassword(password, storedHash)) {
      return Response(401,
          body: jsonEncode({'error': 'Nambari ya simu au password si sahihi'}),
          headers: {'Content-Type': 'application/json'});
    }

    final user = _rowToUser(row);

    return Response.ok(
      jsonEncode({'message': 'Umeingia kikamilifu', 'user': user}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _getUser(Request request) async {
    final id = request.params['id'];
    final conn = await Database.getConnection();
    final results = await conn.mappedResultsQuery(
      'SELECT id, first_name, last_name, email, phone, business_name, location, created_at FROM users WHERE id = @id',
      substitutionValues: {'id': id},
    );

    if (results.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Mtumiaji hajpatikana'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode(_rowToUser(results.first)),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Map<String, dynamic> _rowToUser(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'first_name': row['first_name'],
      'last_name': row['last_name'],
      'email': row['email'],
      'phone': row['phone'],
      'business_name': row['business_name'],
      'location': row['location'],
      'created_at': row['created_at'].toIso8601String(),
    };
  }
}
