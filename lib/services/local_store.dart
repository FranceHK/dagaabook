import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves the app's data on this device only. There is no server or account:
/// everything belongs to the one person using the phone.
class LocalStore {
  LocalStore._();

  static const customersKey = 'customers';
  static const paymentsKey = 'payments';
  static const stockKey = 'stock';
  static const salesKey = 'sales';
  static const profileKey = 'business_profile';
  static const languageKey = 'language';
  static const loginPhoneKey = 'login_phone';
  static const loginPasswordKey = 'login_password';
  static const loggedInKey = 'logged_in';

  static Future<List<T>> loadList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final List<dynamic> data = jsonDecode(raw);
    return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  static Future<Map<String, dynamic>?> loadMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveMap(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// A unique id for a new record, based on the current time.
  static String newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}
