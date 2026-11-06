import 'dart:convert';

import 'package:dagaabook/core/app_version.dart';
import 'package:dagaabook/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('version compare', () {
    expect(AppVersion.isNewer('v1.2.0', '1.1.0'), isTrue);
    expect(AppVersion.isNewer('v1.10.0', '1.9.3'), isTrue);
    expect(AppVersion.isNewer('v1.1.0', '1.1.0'), isFalse);
    expect(AppVersion.isNewer('v1.0.9', '1.1.0'), isFalse);
    expect(AppVersion.isNewer('v2', '1.9.9'), isTrue);
  });

  UpdateService serviceFor(String tag) => UpdateService(
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'tag_name': tag,
                'html_url': 'https://github.com/FranceHK/dagaabook/releases/tag/$tag',
                'assets': [
                  {'name': 'dagaabook-$tag.apk', 'browser_download_url': 'https://example.test/dagaabook-$tag.apk'}
                ],
              }),
              200,
            )),
      );

  test('newer release links to its APK', () async {
    final update = await serviceFor('v1.2.0').check(installed: '1.1.0');
    expect(update?.version, '1.2.0');
    expect(update?.downloadUrl, 'https://example.test/dagaabook-v1.2.0.apk');
  });

  test('same release means no update', () async {
    expect(await serviceFor('v1.1.0').check(installed: '1.1.0'), isNull);
  });
}
