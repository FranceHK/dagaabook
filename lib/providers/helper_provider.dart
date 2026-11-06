import 'package:flutter/foundation.dart';
import '../core/password_hash.dart';
import '../models/helper.dart';
import '../services/local_store.dart';

/// The owner's helper accounts. They reach the helper's phone through the
/// sync server, so helpers only work once online backup is connected.
class HelperProvider extends ChangeNotifier {
  final List<Helper> _helpers = [];

  List<Helper> get helpers => List.unmodifiable(_helpers);

  HelperProvider() {
    loadData();
  }

  Future<void> loadData() async {
    try {
      final list = await LocalStore.loadList(LocalStore.helpersKey, Helper.fromJson);
      _helpers
        ..clear()
        ..addAll(list);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _save() => LocalStore.saveList(LocalStore.helpersKey, _helpers.map((h) => h.toJson()).toList());

  String nameOf(String id) {
    for (final h in _helpers) {
      if (h.id == id) return h.name;
    }
    return '';
  }

  bool phoneTaken(String phone, {String? exceptId}) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return _helpers.any((h) => h.id != exceptId && h.phone.replaceAll(RegExp(r'\D'), '') == digits);
  }

  Future<void> addHelper({required String name, required String phone, required String password}) async {
    final salt = PasswordHash.newSalt();
    final hash = await compute((_) => PasswordHash.hash(password, salt), null);
    _helpers.add(Helper(
      id: LocalStore.newId('helper'),
      name: name,
      phone: phone,
      salt: salt,
      passwordHash: hash,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    await _save();
  }

  /// A new password also signs the helper's phone out.
  Future<void> resetPassword(String id, String password) async {
    final salt = PasswordHash.newSalt();
    final hash = await compute((_) => PasswordHash.hash(password, salt), null);
    _update(id, (h) => h.copyWith(salt: salt, passwordHash: hash));
    await _save();
  }

  /// Stopping a helper blocks their phone at the next sync.
  Future<void> setActive(String id, bool active) async {
    _update(id, (h) => h.copyWith(active: active));
    await _save();
  }

  void _update(String id, Helper Function(Helper) change) {
    final i = _helpers.indexWhere((h) => h.id == id);
    if (i == -1) return;
    _helpers[i] = change(_helpers[i]);
    notifyListeners();
  }
}
