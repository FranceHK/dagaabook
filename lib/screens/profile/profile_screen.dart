import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.deepBlue,
            expandedHeight: 160,
            actions: [
              IconButton(
                icon: const Icon(AmazingIconOutlined.setting),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.heroGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          user != null && user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.fullName ?? 'Mtumiaji',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.phone ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle(title: lang.t('accountInfo')),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: AmazingIconOutlined.user,
                        label: lang.t('ownerName'),
                        value: user?.fullName ?? '-',
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: AmazingIconOutlined.call,
                        label: lang.t('phoneNumber'),
                        value: user?.phone ?? '-',
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: AmazingIconOutlined.location,
                        label: lang.t('location'),
                        value: user?.location ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: lang.t('language')),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LangChip(
                            label: lang.t('swahili'),
                            flag: '🇹🇿',
                            selected: lang.language == AppLanguage.sw,
                            onTap: () => context.read<LanguageProvider>().setLanguage(AppLanguage.sw),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LangChip(
                            label: lang.t('english'),
                            flag: '🇬🇧',
                            selected: lang.language == AppLanguage.en,
                            onTap: () => context.read<LanguageProvider>().setLanguage(AppLanguage.en),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(title: lang.t('about')),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _ProfileTile(
                        icon: AmazingIconOutlined.infoCircle,
                        label: lang.t('version'),
                        value: '1.0.0',
                      ),
                      const Divider(height: 1, indent: 56),
                      _ProfileTile(
                        icon: AmazingIconOutlined.data,
                        label: lang.t('dataMode'),
                        value: lang.t('localMockData'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, lang),
                    icon: const Icon(AmazingIconOutlined.logout, size: 18, color: AppColors.danger),
                    label: Text(
                      lang.t('logout'),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.t('logout')),
        content: Text(lang.t('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Text(lang.t('confirm'), style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, size: 20, color: AppColors.deepBlue),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.deepBlue.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.deepBlue : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? AppColors.deepBlue : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
