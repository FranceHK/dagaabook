import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final settings = context.watch<SettingsProvider>();
    final profile = settings.profile;

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('settingsTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: lang.t('businessProfile'),
            child: Column(
              children: [
                _ProfileRow(icon: AmazingIconOutlined.shop, label: lang.t('businessName'), value: profile.businessName),
                const Divider(height: 20),
                _ProfileRow(icon: AmazingIconOutlined.user, label: lang.t('ownerName'), value: profile.ownerName),
                const Divider(height: 20),
                _ProfileRow(icon: AmazingIconOutlined.call, label: lang.t('phoneNumber'), value: profile.phone),
                const Divider(height: 20),
                _ProfileRow(icon: AmazingIconOutlined.location, label: lang.t('location'), value: profile.location),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: lang.t('currency'),
            child: _ProfileRow(icon: AmazingIconOutlined.wallet, label: lang.t('currency'), value: '${profile.currency} (TSh)'),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: lang.t('language'),
            child: Row(
              children: [
                Expanded(
                  child: _LanguageOption(
                    label: lang.t('swahili'),
                    flagEmoji: '🇹🇿',
                    selected: lang.language == AppLanguage.sw,
                    onTap: () => context.read<LanguageProvider>().setLanguage(AppLanguage.sw),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LanguageOption(
                    label: lang.t('english'),
                    flagEmoji: '🇬🇧',
                    selected: lang.language == AppLanguage.en,
                    onTap: () => context.read<LanguageProvider>().setLanguage(AppLanguage.en),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: lang.t('about'),
            child: Column(
              children: [
                _ProfileRow(icon: AmazingIconOutlined.infoCircle, label: lang.t('version'), value: '1.0.0'),
                const Divider(height: 20),
                _ProfileRow(icon: AmazingIconOutlined.data, label: lang.t('dataMode'), value: lang.t('localMockData')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.deepBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
        ),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String flagEmoji;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({required this.label, required this.flagEmoji, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepBlue.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.deepBlue : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: selected ? AppColors.deepBlue : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
