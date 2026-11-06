import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Must match lib/core/password_hash.dart in the app.
String hashPassword(String password, String salt) {
  List<int> digest = utf8.encode('$salt:$password');
  for (var i = 0; i < 20000; i++) {
    digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
  }
  return base64Url.encode(digest);
}

/// Token a helper's phone uses for its requests. It changes when the owner
/// resets the helper's password, which signs the old phone out.
String helperToken(String syncKey, String helperId, String passwordHash) {
  final mac = Hmac(sha256, utf8.encode(syncKey)).convert(utf8.encode('$helperId:$passwordHash'));
  return base64Url.encode(mac.bytes).replaceAll('=', '');
}

/// Compares in constant time so secrets can't be guessed from timing.
bool sameText(String a, String b) {
  if (a.length != b.length || b.isEmpty) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
