import 'package:flutter/foundation.dart';
import '../core/app_owner.dart';
import '../services/local_store.dart';

/// Login for the app's single owner. Checked on the phone itself, so it
/// works with or without internet. The session is remembered until logout.
class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoaded = false;
  String _phone = AppOwner.defaultPhone;
  String _password = AppOwner.defaultPassword;
  String? _error;

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

  Future<void> logout() async {
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
    await LocalStore.saveString(LocalStore.loggedInKey, 'false');
  }
}
