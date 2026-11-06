import 'package:flutter/foundation.dart';
import '../core/app_owner.dart';
import '../services/local_store.dart';

/// Login for the owner (checked on the phone itself, so it works with or
/// without internet) or for a helper (checked once by the sync server, then
/// remembered on the helper's phone). The session lasts until logout.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoaded = false;
  String _phone = AppOwner.defaultPhone;
  String _password = AppOwner.defaultPassword;
  String? _error;
  bool _isHelper = false;
  String _helperId = '';
  String _helperName = '';

  bool get isHelper => _isHelper;
  String get helperId => _helperId;
  String get helperName => _helperName;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoaded => _isLoaded;
  String get phone => _phone;
  String? get error => _error;

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      _phone = await LocalStore.loadString(LocalStore.loginPhoneKey) ?? AppOwner.defaultPhone;
      _password = await LocalStore.loadString(LocalStore.loginPasswordKey) ?? AppOwner.defaultPassword;
      _isLoggedIn = await LocalStore.loadString(LocalStore.loggedInKey) == 'true';
      _isHelper = await LocalStore.loadString(LocalStore.roleKey) == 'helper';
      _helperId = await LocalStore.loadString(LocalStore.helperIdKey) ?? '';
      _helperName = await LocalStore.loadString(LocalStore.helperNameKey) ?? '';
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  Future<bool> login({required String phone, required String password}) async {
    _error = null;
    if (_digits(phone) != _digits(_phone) || password != _password) {
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
    if (currentPassword != _password) return false;
    _phone = newPhone;
    _password = newPassword;
    notifyListeners();
    await LocalStore.saveString(LocalStore.loginPhoneKey, newPhone);
    await LocalStore.saveString(LocalStore.loginPasswordKey, newPassword);
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
