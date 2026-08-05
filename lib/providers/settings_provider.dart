import 'package:flutter/foundation.dart';
import '../models/business_profile.dart';

/// Business profile & app settings. Backed by local state for now; will be
/// persisted to the backend once Neon Postgres is connected.
class SettingsProvider extends ChangeNotifier {
  BusinessProfile _profile = const BusinessProfile(
    businessName: 'Mwanza Dagaa Traders',
    ownerName: 'Baba Juma',
    phone: '0755 123 456',
    location: 'Kirumba, Mwanza',
    currency: 'TZS',
  );

  BusinessProfile get profile => _profile;

  void updateProfile(BusinessProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}
