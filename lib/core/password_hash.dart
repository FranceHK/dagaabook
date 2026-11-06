import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Hashes helper passwords before they leave the phone. Must match
/// server/lib/passwords.dart, which checks them at helper login.
class PasswordHash {
  PasswordHash._();

  static String hash(String password, String salt) {
    List<int> digest = utf8.encode('$salt:$password');
    for (var i = 0; i < 20000; i++) {
      digest = sha256.convert([...digest, ...utf8.encode(salt)]).bytes;
    }
    return base64Url.encode(digest);
  }

  static String newSalt() {
    final random = Random.secure();
    return base64Url.encode(List.generate(16, (_) => random.nextInt(256)));
  }
}
