import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../providers/language_provider.dart';
import '../../providers/sync_provider.dart';
import '../profile/edit_profile_sheet.dart';

/// Settings card for the online backup to the sync server (Neon database).
class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  static final _time = DateFormat('HH:mm');

  static String errorText(LanguageProvider lang, String code) => switch (code) {
    'offline' => lang.t('syncErrOffline'),
    'unauthorized' => lang.t('syncErrUnauthorized'),
    'empty' => lang.t('syncErrEmpty'),
    _ => lang.t('syncErrServer'),
  };

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final sync = context.watch<SyncProvider>();
    final last = sync.lastSync;

    final String status;
    final Color statusColor;
    if (!sync.isConfigured) {
      status = lang.t('notConnected');
      statusColor = AppColors.textSecondary;
    } else if (sync.error != null) {
      status = errorText(lang, sync.error!);
      statusColor = AppColors.danger;
    } else if (sync.hasPending) {
      status = lang.t('syncPending');
      statusColor = AppColors.warning;
    } else {
      status = sync.autoSync ? lang.t('autoBackupOn') : lang.t('autoBackupOff');
      statusColor = sync.autoSync ? AppColors.success : AppColors.textSecondary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(sync.isConfigured ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, size: 20, color: AppColors.deepBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sync.isConfigured ? Uri.tryParse(sync.serverUrl)?.host ?? sync.serverUrl : lang.t('notConnected'),
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _ServerSheet(),
              ),
              child: Text(lang.t(sync.isConfigured ? 'edit' : 'syncSetup')),
            ),
          ],
        ),
        const Divider(height: 20),
        Row(
          children: [
            const Icon(Icons.history, size: 20, color: AppColors.deepBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(lang.t('lastSync'), style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
            ),
            Text(
              last == null ? lang.t('neverSynced') : '${AppFormatters.date(last)} ${_time.format(last)}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          status,
          style: TextStyle(fontSize: 12.5, color: statusColor, fontWeight: FontWeight.w600),
        ),
        if (sync.isConfigured) ...[
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: sync.isBusy ? null : () => _syncNow(context),
            icon: sync.isBusy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_sync_outlined, size: 18),
            label: Text(lang.t('syncNow')),
          ),
        ],
      ],
    );
  }

  Future<void> _syncNow(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final sync = context.read<SyncProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await sync.syncNow();
    messenger.showSnackBar(SnackBar(content: Text(ok ? lang.t('syncDone') : errorText(lang, sync.error ?? ''))));
  }
}

class _ServerSheet extends StatefulWidget {
  const _ServerSheet();

  @override
  State<_ServerSheet> createState() => _ServerSheetState();
}

class _ServerSheetState extends State<_ServerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _urlController = TextEditingController(text: context.read<SyncProvider>().serverUrl);
  late final _keyController = TextEditingController(text: context.read<SyncProvider>().syncKey);
  bool _showKey = false;

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return SheetFrame(
      title: lang.t('backupTitle'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(labelText: lang.t('serverUrl'), hintText: 'https://dagaabook-sync.onrender.com'),
              validator: (v) {
                final uri = Uri.tryParse(v?.trim() ?? '');
                final valid = uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
                return valid ? null : lang.t('invalidUrl');
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _keyController,
              obscureText: !_showKey,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: lang.t('syncKeyLabel'),
                suffixIcon: IconButton(
                  icon: Icon(_showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _showKey = !_showKey),
                ),
              ),
              validator: (v) => (v ?? '').trim().length < 12 ? lang.t('keyTooShort') : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: Text(lang.t('save'))),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<SyncProvider>().configure(serverUrl: _urlController.text, syncKey: _keyController.text);
    if (mounted) Navigator.of(context).pop();
  }
}
