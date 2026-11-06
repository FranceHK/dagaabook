import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves the app's data on this device. Everything belongs to the one person
/// using the phone; a backup can be sent to the sync server (see SyncService).
class LocalStore {
  LocalStore._();

  static const customersKey = 'customers';
  static const paymentsKey = 'payments';
  static const stockKey = 'stock';
  static const salesKey = 'sales';
  static const profileKey = 'business_profile';
  static const languageKey = 'language';
  // Plain-text login from older versions; moved into [accountKey] on load.
  static const loginPhoneKey = 'login_phone';
  static const loginPasswordKey = 'login_password';
  static const loggedInKey = 'logged_in';
  static const helpersKey = 'helpers';
  static const accountKey = 'account';
  static const roleKey = 'role';
  static const helperIdKey = 'helper_id';
  static const helperNameKey = 'helper_name';
  static const syncUrlKey = 'sync_url';
  static const syncSecretKey = 'sync_key';
  static const lastSyncKey = 'last_sync';
  static const syncAutoKey = 'sync_auto';
  static const syncPendingKey = 'sync_pending';

  /// The keys whose changes should be backed up.
  static const dataKeys = {customersKey, paymentsKey, stockKey, salesKey, profileKey, helpersKey, accountKey};

  /// Called after business data is saved, so a backup can follow.
  static void Function()? onDataChanged;

  static void _changed(String key) {
    if (dataKeys.contains(key)) onDataChanged?.call();
  }

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

  static Future<void> saveList(String key, List<Map<String, dynamic>> items, {bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
    if (notify) _changed(key);
  }

  static Future<Map<String, dynamic>?> loadMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveMap(String key, Map<String, dynamic> value, {bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
    if (notify) _changed(key);
  }

  static Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static final _random = Random();

  /// A unique id for a new record. The random part keeps ids from two phones
  /// (owner and helper) apart even when made at the same moment.
  static String newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(0x7fffffff).toRadixString(36)}';
}
