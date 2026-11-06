import 'package:flutter/foundation.dart';
import '../core/app_owner.dart';
import '../models/business_profile.dart';
import '../services/local_store.dart';

/// The owner's business profile, saved on this device.
class SettingsProvider extends ChangeNotifier {
  BusinessProfile _profile = AppOwner.defaultProfile;

  BusinessProfile get profile => _profile;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final json = await LocalStore.loadMap(LocalStore.profileKey);
      if (json != null) {
        _profile = BusinessProfile.fromJson(json);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateProfile(BusinessProfile profile) async {
    _profile = profile;
    notifyListeners();
    await LocalStore.saveMap(LocalStore.profileKey, profile.toJson());
  }
}
