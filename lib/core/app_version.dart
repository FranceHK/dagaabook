/// The version of this build. CI passes it with
/// `--dart-define=APP_VERSION=1.2.0`; local builds are "dev" and skip
/// update checks.
class AppVersion {
  AppVersion._();

  static const current = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  static bool get isRelease => current != 'dev';

  /// True when [candidate] (like "v1.2.0" or "1.2.0") is later than [installed].
  static bool isNewer(String candidate, String installed) {
    final a = _parts(candidate);
    final b = _parts(installed);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  static List<int> _parts(String version) {
    final clean = version.trim().replaceFirst(RegExp(r'^v'), '').split('+').first;
    final parts = clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}
