import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_version.dart';
import '../providers/language_provider.dart';
import '../services/update_service.dart';

/// Checks GitHub for a newer APK once when the app opens and offers to
/// download it. Used on both the owner's and the helper's screens.
class UpdatePrompt extends StatefulWidget {
  final Widget child;

  const UpdatePrompt({super.key, required this.child});

  /// Asks GitHub now. With [quiet] nothing is shown unless there is an update.
  static Future<void> check(BuildContext context, {bool quiet = false}) async {
    final lang = context.read<LanguageProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final update = await UpdateService().check();
      if (!context.mounted) return;
      if (update != null) {
        await _offer(context, update);
      } else if (!quiet) {
        messenger.showSnackBar(SnackBar(content: Text(lang.t('upToDate'))));
      }
    } catch (_) {
      if (!quiet) messenger.showSnackBar(SnackBar(content: Text(lang.t('updateCheckFailed'))));
    }
  }

  static Future<void> _offer(BuildContext context, AppUpdate update) async {
    final lang = context.read<LanguageProvider>();
    final download = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.system_update_outlined),
        title: Text(lang.t('updateTitle')),
        content: Text(lang.t('updateBody').replaceAll('{version}', update.version)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.t('updateLater'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(lang.t('updateDownload'))),
        ],
      ),
    );
    if (download == true) {
      await launchUrl(Uri.parse(update.downloadUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  State<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<UpdatePrompt> {
  @override
  void initState() {
    super.initState();
    // Only installed release builds can be updated this way.
    if (AppVersion.isRelease && !kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) UpdatePrompt.check(context, quiet: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
