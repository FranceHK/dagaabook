import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/local_store.dart';
import '../services/sync_service.dart';

/// Keeps the backup on the sync server up to date. Works offline: changes are
/// marked as pending and sent the next time the server can be reached.
class SyncProvider extends ChangeNotifier {
  SyncProvider({SyncService? service}) : _service = service ?? SyncService() {
    LocalStore.onDataChanged = _onDataChanged;
    _load();
  }

  final SyncService _service;
  Timer? _debounce;

  String _serverUrl = '';
  String _syncKey = '';
  DateTime? _lastSync;
  bool _autoSync = false;
  bool _pending = false;
  bool _busy = false;
  String? _error;

  String get serverUrl => _serverUrl;
  String get syncKey => _syncKey;
  DateTime? get lastSync => _lastSync;
  bool get isConfigured => _serverUrl.isNotEmpty && _syncKey.isNotEmpty;
  bool get autoSync => _autoSync;
  bool get hasPending => _pending;
  bool get isBusy => _busy;

  /// The last failure code from [SyncException], or null after a success.
  String? get error => _error;

  Future<void> _load() async {
    _serverUrl = await LocalStore.loadString(LocalStore.syncUrlKey) ?? '';
    _syncKey = await LocalStore.loadString(LocalStore.syncSecretKey) ?? '';
    _lastSync = DateTime.tryParse(await LocalStore.loadString(LocalStore.lastSyncKey) ?? '');
    _autoSync = await LocalStore.loadString(LocalStore.syncAutoKey) == 'true';
    _pending = await LocalStore.loadString(LocalStore.syncPendingKey) == 'true';
    notifyListeners();
    if (_pending) _schedule(const Duration(seconds: 2));
  }

  Future<void> configure({required String serverUrl, required String syncKey}) async {
    _serverUrl = serverUrl.trim();
    _syncKey = syncKey.trim();
    _error = null;
    notifyListeners();
    await LocalStore.saveString(LocalStore.syncUrlKey, _serverUrl);
    await LocalStore.saveString(LocalStore.syncSecretKey, _syncKey);
  }

  void _onDataChanged() {
    if (!_pending) {
      _pending = true;
      notifyListeners();
      LocalStore.saveString(LocalStore.syncPendingKey, 'true');
    }
    _schedule(const Duration(seconds: 4));
  }

  void _schedule(Duration delay) {
    // Auto backup starts only after a manual sync or restore on this phone,
    // so a fresh install can't overwrite the backup by accident.
    if (!_autoSync || !isConfigured) return;
    _debounce?.cancel();
    _debounce = Timer(delay, () => syncNow());
  }

  /// Sends all data to the server. Returns true on success.
  Future<bool> syncNow() async {
    if (!isConfigured || _busy) return false;
    return _run(() => _service.upload(_serverUrl, _syncKey));
  }

  /// Replaces this phone's data with the server backup. The caller reloads
  /// the other providers afterwards.
  Future<bool> restore() async {
    if (!isConfigured || _busy) return false;
    return _run(() => _service.restore(_serverUrl, _syncKey));
  }

  Future<bool> _run(Future<DateTime> Function() action) async {
    _debounce?.cancel();
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _lastSync = await action();
      _pending = false;
      _autoSync = true;
      await LocalStore.saveString(LocalStore.lastSyncKey, _lastSync!.toIso8601String());
      await LocalStore.saveString(LocalStore.syncAutoKey, 'true');
      await LocalStore.saveString(LocalStore.syncPendingKey, 'false');
      return true;
    } on SyncException catch (e) {
      _error = e.code;
      return false;
    } catch (_) {
      _error = 'unknown';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (LocalStore.onDataChanged == _onDataChanged) LocalStore.onDataChanged = null;
    super.dispose();
  }
}
