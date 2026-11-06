import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_version.dart';

/// A newer APK published on GitHub Releases.
class AppUpdate {
  final String version;
  final String downloadUrl;
  const AppUpdate({required this.version, required this.downloadUrl});
}

/// Looks for a newer release of the app. Releases are made by pushing a tag
/// like v1.2.0; the GitHub workflow attaches the signed APK to it.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _latestRelease = Uri.parse('https://api.github.com/repos/FranceHK/dagaabook/releases/latest');

  /// Returns the update, or null when this build is the latest. Throws when
  /// GitHub can't be reached.
  Future<AppUpdate?> check({String installed = AppVersion.current}) async {
    final response = await _client
        .get(_latestRelease, headers: {'accept': 'application/vnd.github+json'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw Exception('GitHub ${response.statusCode}');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = json['tag_name'] as String? ?? '';
    if (!AppVersion.isNewer(tag, installed)) return null;

    final assets = (json['assets'] as List? ?? const []).cast<Map<String, dynamic>>();
    final apk = assets.where((a) => '${a['name']}'.endsWith('.apk')).firstOrNull;
    return AppUpdate(
      version: tag.replaceFirst(RegExp(r'^v'), ''),
      downloadUrl: '${apk?['browser_download_url'] ?? json['html_url']}',
    );
  }
}
