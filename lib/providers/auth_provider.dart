import 'package:flutter/foundation.dart';
import '../core/app_owner.dart';
import '../core/password_hash.dart';
import '../services/local_store.dart';

/// Login for the owner (checked on the phone itself, so it works with or
/// without internet) or for a helper (checked once by the sync server, then
/// remembered on the helper's phone). The session lasts until logout.
///
/// The owner's phone and hashed password are kept in the `account` record,
/// which syncs to the database. Setting `new_password` on that record in the
/// database resets the password on the next sync.
class AuthProvider extends ChangeNotifier {
  static const accountId = 'owner';

  bool _isLoggedIn = false;
  bool _isLoaded = false;
  Map<String, dynamic>? _account;
  String? _error;
  bool _isHelper = false;
  String _helperId = '';
  String _helperName = '';

  bool get isHelper => _isHelper;
  String get helperId => _helperId;
  String get helperName => _helperName;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoaded => _isLoaded;
  String get phone => _account?['phone'] as String? ?? AppOwner.defaultPhone;
  String? get error => _error;

  AuthProvider() {
    loadData();
  }

  /// Reads the session and the owner login. Also called after each sync, in
  /// case the login was changed in the database.
  Future<void> loadData() async {
    try {
      _isLoggedIn = await LocalStore.loadString(LocalStore.loggedInKey) == 'true';
      _isHelper = await LocalStore.loadString(LocalStore.roleKey) == 'helper';
      _helperId = await LocalStore.loadString(LocalStore.helperIdKey) ?? '';
      _helperName = await LocalStore.loadString(LocalStore.helperNameKey) ?? '';
      _account = await _loadAccount();
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _loadAccount() async {
    final list = await LocalStore.loadList(LocalStore.accountKey, (json) => json);
    var account = list.where((a) => a['id'] == accountId).firstOrNull;

    // Logins saved by older versions were kept in plain text on the phone.
    final oldPhone = await LocalStore.loadString(LocalStore.loginPhoneKey);
    final oldPassword = await LocalStore.loadString(LocalStore.loginPasswordKey);
    if (account == null && oldPhone != null && oldPassword != null) {
      account = await _saveAccount(phone: oldPhone, password: oldPassword);
    }
    if (oldPhone != null || oldPassword != null) {
      await LocalStore.remove(LocalStore.loginPhoneKey);
      await LocalStore.remove(LocalStore.loginPasswordKey);
    }

    final reset = account?['new_password'];
    if (account != null && reset is String && reset.isNotEmpty) {
      account = await _saveAccount(phone: '${account['phone'] ?? AppOwner.defaultPhone}', password: reset);
    }
    return account;
  }

  Future<Map<String, dynamic>> _saveAccount({required String phone, required String password}) async {
    final salt = PasswordHash.newSalt();
    final account = {
      'id': accountId,
      'phone': phone,
      'salt': salt,
      'password_hash': await compute((_) => PasswordHash.hash(password, salt), null),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await LocalStore.saveList(LocalStore.accountKey, [account]);
    return account;
  }

  Future<bool> _passwordMatches(String password) async {
    final account = _account;
    if (account == null || account['password_hash'] == null) return password == AppOwner.defaultPassword;
    final salt = '${account['salt']}';
    final hash = await compute((_) => PasswordHash.hash(password, salt), null);
    return hash == account['password_hash'];
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  Future<bool> login({required String phone, required String password}) async {
    _error = null;
    if (_digits(phone) != _digits(this.phone) || !await _passwordMatches(password)) {
      _error = 'Namba ya simu au nywila si sahihi';
      notifyListeners();
      return false;
    }
    _isLoggedIn = true;
    notifyListeners();
    await LocalStore.saveString(LocalStore.loggedInKey, 'true');
    return true;
  }

  /// Returns false when [currentPassword] is wrong.
  Future<bool> changeLogin({
    required String currentPassword,
    required String newPhone,
    required String newPassword,
  }) async {
    if (!await _passwordMatches(currentPassword)) return false;
    _account = await _saveAccount(phone: newPhone, password: newPassword);
    notifyListeners();
    return true;
  }

  /// Signs a helper in after the server accepted their phone and password.
  Future<void> startHelperSession({required String id, required String name}) async {
    _isHelper = true;
    _helperId = id;
    _helperName = name;
    _isLoggedIn = true;
    _error = null;
    await LocalStore.saveString(LocalStore.roleKey, 'helper');
    await LocalStore.saveString(LocalStore.helperIdKey, id);
    await LocalStore.saveString(LocalStore.helperNameKey, name);
    await LocalStore.saveString(LocalStore.loggedInKey, 'true');
    notifyListeners();
  }

  /// A helper's logout also removes the owner's data from the helper's phone.
  Future<void> logout() async {
    _isLoggedIn = false;
    _error = null;
    if (_isHelper) {
      for (final key in [...LocalStore.dataKeys, LocalStore.roleKey, LocalStore.helperIdKey, LocalStore.helperNameKey]) {
        await LocalStore.remove(key);
      }
      _isHelper = false;
      _helperId = '';
      _helperName = '';
    }
    notifyListeners();
    await LocalStore.saveString(LocalStore.loggedInKey, 'false');
  }
}
