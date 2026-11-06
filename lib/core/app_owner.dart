import '../models/business_profile.dart';

/// The one person this app is made for. There is no registration: the app
/// has a single account, and these are its starting details. The owner can
/// change the password and business details from inside the app.
class AppOwner {
  AppOwner._();

  static const String defaultPhone = '0700000000';
  static const String defaultPassword = 'dagaa2026';

  static const BusinessProfile defaultProfile = BusinessProfile(
    businessName: 'DagaaBook',
    ownerName: 'Mmiliki',
    phone: defaultPhone,
    location: 'Mwanza',
    currency: 'TZS',
  );
}
