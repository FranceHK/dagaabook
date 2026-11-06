import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/app_colors.dart';
import '../../models/helper.dart';
import '../../providers/helper_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sync_provider.dart';
import '../profile/edit_profile_sheet.dart';

/// Settings card where the owner adds, stops and resets helper accounts.
class HelpersSection extends StatelessWidget {
  const HelpersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final helpers = context.watch<HelperProvider>().helpers;
    final sync = context.watch<SyncProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(lang.t('helpersNote'), style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        if (!sync.isConfigured)
          Text(lang.t('helpersNeedBackup'), style: const TextStyle(fontSize: 12.5, color: AppColors.warning, fontWeight: FontWeight.w600))
        else ...[
          Text(lang.t('helperLoginInfo'), style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          SelectableText(sync.serverUrl, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 8),
        if (helpers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(lang.t('noHelpers'), style: const TextStyle(fontSize: 13.5)),
          ),
        for (final helper in helpers) _HelperTile(helper: helper),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _openSheet(context, const _HelperSheet()),
          icon: const Icon(AmazingIconOutlined.userAdd, size: 18),
          label: Text(lang.t('addHelper')),
        ),
      ],
    );
  }
}

void _openSheet(BuildContext context, Widget sheet) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );

class _HelperTile extends StatelessWidget {
  final Helper helper;

  const _HelperTile({required this.helper});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final provider = context.read<HelperProvider>();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: (helper.active ? AppColors.deepBlue : AppColors.textSecondary).withValues(alpha: 0.1),
        child: Icon(AmazingIconOutlined.user, size: 18, color: helper.active ? AppColors.deepBlue : AppColors.textSecondary),
      ),
      title: Text(helper.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        '${helper.phone} · ${lang.t(helper.active ? 'helperActive' : 'helperStopped')}',
        style: TextStyle(fontSize: 12.5, color: helper.active ? AppColors.success : AppColors.danger),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          if (action == 'toggle') provider.setActive(helper.id, !helper.active);
          if (action == 'password') _openSheet(context, _HelperSheet(helper: helper));
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'password', child: Text(lang.t('resetPassword'))),
          PopupMenuItem(value: 'toggle', child: Text(lang.t(helper.active ? 'stopHelper' : 'allowHelper'))),
        ],
      ),
    );
  }
}

/// Adds a helper, or sets a new password when [helper] is given.
class _HelperSheet extends StatefulWidget {
  final Helper? helper;

  const _HelperSheet({this.helper});

  @override
  State<_HelperSheet> createState() => _HelperSheetState();
}

class _HelperSheetState extends State<_HelperSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _saving = false;

  bool get _isReset => widget.helper != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final provider = context.read<HelperProvider>();

    return SheetFrame(
      title: _isReset ? '${lang.t('resetPassword')}: ${widget.helper!.name}' : lang.t('addHelper'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isReset) ...[
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: lang.t('helperName')),
                validator: (v) => (v ?? '').trim().isEmpty ? lang.t('required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: lang.t('phoneNumber')),
                validator: (v) {
                  if ((v ?? '').replaceAll(RegExp(r'\D'), '').length < 9) return lang.t('enterPhone');
                  if (provider.phoneTaken(v!)) return lang.t('phoneTaken');
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: lang.t('helperPassword')),
              validator: (v) => (v ?? '').length < 6 ? lang.t('helperPasswordShort') : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(lang.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<HelperProvider>();
    if (_isReset) {
      await provider.resetPassword(widget.helper!.id, _passwordController.text);
    } else {
      await provider.addHelper(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }
}
