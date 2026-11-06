import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/business_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';

class _SheetFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetFrame({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets the owner change the business name, their name, phone and location.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _businessController = TextEditingController(text: _profile.businessName);
  late final _ownerController = TextEditingController(text: _profile.ownerName);
  late final _phoneController = TextEditingController(text: _profile.phone);
  late final _locationController = TextEditingController(text: _profile.location);

  BusinessProfile get _profile => context.read<SettingsProvider>().profile;

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    String? required(String? v) => (v == null || v.trim().isEmpty) ? lang.t('required') : null;

    return _SheetFrame(
      title: lang.t('editProfile'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _businessController,
              decoration: InputDecoration(labelText: lang.t('businessName')),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ownerController,
              decoration: InputDecoration(labelText: lang.t('ownerName')),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: lang.t('phoneNumber')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: lang.t('location')),
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
    final settings = context.read<SettingsProvider>();
    await settings.updateProfile(settings.profile.copyWith(
      businessName: _businessController.text.trim(),
      ownerName: _ownerController.text.trim(),
      phone: _phoneController.text.trim(),
      location: _locationController.text.trim(),
    ));
    if (mounted) Navigator.of(context).pop();
  }
}

/// Lets the owner change the phone number and password used to log in.
class ChangeLoginSheet extends StatefulWidget {
  const ChangeLoginSheet({super.key});

  @override
  State<ChangeLoginSheet> createState() => _ChangeLoginSheetState();
}

class _ChangeLoginSheetState extends State<ChangeLoginSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _phoneController = TextEditingController(text: context.read<AuthProvider>().phone);
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return _SheetFrame(
      title: lang.t('changeLogin'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: lang.t('phoneNumber')),
              validator: (v) => (v == null || v.trim().isEmpty) ? lang.t('enterPhone') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentController,
              obscureText: true,
              decoration: InputDecoration(labelText: lang.t('currentPassword')),
              validator: (v) => (v == null || v.isEmpty) ? lang.t('required') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newController,
              obscureText: true,
              decoration: InputDecoration(labelText: lang.t('newPassword')),
              validator: (v) => (v == null || v.length < 4) ? lang.t('enterPassword') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(labelText: lang.t('confirmPassword')),
              validator: (v) => v != _newController.text ? lang.t('passwordMismatch') : null,
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
    final lang = context.read<LanguageProvider>();
    final ok = await context.read<AuthProvider>().changeLogin(
          currentPassword: _currentController.text,
          newPhone: _phoneController.text.trim(),
          newPassword: _newController.text,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.t(ok ? 'saved' : 'wrongPassword'))),
    );
    if (ok) Navigator.of(context).pop();
  }
}
