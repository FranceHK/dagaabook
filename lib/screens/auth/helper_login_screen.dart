import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';
import '../settings/backup_section.dart';

/// Login for a helper on their own phone. The server checks the phone and
/// password the owner set, then the owner's customers and stock are
/// downloaded so the helper can sell, even offline afterwards.
class HelperLoginScreen extends StatefulWidget {
  const HelperLoginScreen({super.key});

  @override
  State<HelperLoginScreen> createState() => _HelperLoginScreenState();
}

class _HelperLoginScreenState extends State<HelperLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _urlController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = context.read<LanguageProvider>();
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final url = _urlController.text.trim();

    setState(() => _busy = true);
    try {
      final session = await sync.service.helperLogin(url, _phoneController.text.trim(), _passwordController.text);
      await sync.configure(serverUrl: url, syncKey: session.token);
      await auth.startHelperSession(id: session.id, name: session.name);
      await sync.syncNow();
      navigator.popUntil((route) => route.isFirst);
    } on SyncException catch (e) {
      final text = e.code == 'unauthorized' ? lang.t('helperWrongLogin') : BackupSection.errorText(lang, e.code);
      messenger.showSnackBar(SnackBar(content: Text(text)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(lang.t('helperLoginTitle'))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      lang.t('helperLoginSubtitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: lang.t('serverUrl'),
                        hintText: 'https://dagaabook-sync.onrender.com',
                        prefixIcon: const Icon(Icons.cloud_outlined, size: 20),
                      ),
                      validator: (v) {
                        final uri = Uri.tryParse(v?.trim() ?? '');
                        final valid = uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
                        return valid ? null : lang.t('invalidUrl');
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: lang.t('phoneNumber'),
                        hintText: '07XX XXX XXX',
                        prefixIcon: const Icon(AmazingIconOutlined.call, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? lang.t('enterPhone') : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: lang.t('password'),
                        prefixIcon: const Icon(AmazingIconOutlined.lock, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? AmazingIconOutlined.eye : AmazingIconOutlined.eyeSlash, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? lang.t('required') : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(lang.t('loginButton')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
