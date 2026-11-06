import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/local_store.dart';
import '../services/sync_service.dart';

/// Keeps this phone and the sync server in step. Works offline: changes are
/// marked as pending and sent the next time the server can be reached.
class SyncProvider extends ChangeNotifier {
  SyncProvider({SyncService? service}) : _service = service ?? SyncService() {
    LocalStore.onDataChanged = _onDataChanged;
    _load();
  }

  final SyncService _service;
  Timer? _debounce;
  Timer? _poll;

  /// How often an open app checks for the other phone's sales.
  static const pollInterval = Duration(minutes: 3);

  /// Called after a sync brings in new data, so screens can reload it.
  List<Future<void> Function()> reloaders = [];

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

  SyncService get service => _service;

  Future<void> _load() async {
    _serverUrl = await LocalStore.loadString(LocalStore.syncUrlKey) ?? '';
    _syncKey = await LocalStore.loadString(LocalStore.syncSecretKey) ?? '';
    _lastSync = DateTime.tryParse(await LocalStore.loadString(LocalStore.lastSyncKey) ?? '');
    _autoSync = await LocalStore.loadString(LocalStore.syncAutoKey) == 'true';
    _pending = await LocalStore.loadString(LocalStore.syncPendingKey) == 'true';
    notifyListeners();
    // Also pulls in what the other phone did since last time.
    _schedule(const Duration(seconds: 2));
    _poll = Timer.periodic(pollInterval, (_) => _schedule(Duration.zero));
  }

  Future<void> configure({required String serverUrl, required String syncKey}) async {
    _serverUrl = serverUrl.trim();
    _syncKey = syncKey.trim();
    _error = null;
    notifyListeners();
    await LocalStore.saveString(LocalStore.syncUrlKey, _serverUrl);
    await LocalStore.saveString(LocalStore.syncSecretKey, _syncKey);
  }

  /// Forgets the server and the sync history (used when a helper logs out).
  Future<void> reset() async {
    _debounce?.cancel();
    _serverUrl = '';
    _syncKey = '';
    _lastSync = null;
    _autoSync = false;
    _pending = false;
    _error = null;
    notifyListeners();
    for (final key in [
      LocalStore.syncUrlKey,
      LocalStore.syncSecretKey,
      LocalStore.lastSyncKey,
      LocalStore.syncAutoKey,
      LocalStore.syncPendingKey,
    ]) {
      await LocalStore.remove(key);
    }
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
    if (!_autoSync || !isConfigured) return;
    _debounce?.cancel();
    _debounce = Timer(delay, () => syncNow());
  }

  /// Sends this phone's data and merges in the server's. Returns true on
  /// success. After the first success, syncing happens by itself.
  Future<bool> syncNow() async {
    if (!isConfigured || _busy) return false;
    _debounce?.cancel();
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final isOwner = await LocalStore.loadString(LocalStore.roleKey) != 'helper';
      _lastSync = await _service.sync(_serverUrl, _syncKey, preferLocal: isOwner);
      _pending = false;
      _autoSync = true;
      await LocalStore.saveString(LocalStore.lastSyncKey, _lastSync!.toIso8601String());
      await LocalStore.saveString(LocalStore.syncAutoKey, 'true');
      await LocalStore.saveString(LocalStore.syncPendingKey, 'false');
      await Future.wait(reloaders.map((reload) => reload()));
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
    _poll?.cancel();
    if (LocalStore.onDataChanged == _onDataChanged) LocalStore.onDataChanged = null;
    super.dispose();
  }
}
