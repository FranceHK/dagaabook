import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  AuthProvider() {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await ApiService.checkConnection()) {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phone': phone, 'password': password}),
        ).timeout(ApiService.timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _user = User.fromJson(data['user']);
          await _saveUser(_user!);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          final data = jsonDecode(response.body);
          _error = data['error'] ?? 'Login imeshindwa';
        }
      } else {
        _error = 'Haijaungana na server. Tumia mode ya ndani.';
      }
    } catch (e) {
      _error = 'Hitilafu imetokea. Jaribu tena.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (await ApiService.checkConnection()) {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'phone': phone,
            'password': password,
          }),
        ).timeout(ApiService.timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _user = User.fromJson(data['user']);
          await _saveUser(_user!);
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          final data = jsonDecode(response.body);
          _error = data['error'] ?? 'Usajili umeshindwa';
        }
      } else {
        _error = 'Haijaungana na server. Tumia mode ya ndani.';
      }
    } catch (e) {
      _error = 'Hitilafu imetokea. Jaribu tena.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void loginLocal({required String firstName, required String lastName, String phone = ''}) {
    _user = User(
      id: 'local_user',
      firstName: firstName.isNotEmpty ? firstName : 'Mtumiaji',
      lastName: lastName,
      phone: phone.isNotEmpty ? phone : '0700 000 000',
      createdAt: DateTime.now(),
    );
    _saveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    await _clearUser();
    notifyListeners();
  }
}
