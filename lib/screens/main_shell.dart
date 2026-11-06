import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../core/app_colors.dart';
import '../core/debt_calculator.dart';
import '../core/responsive.dart';
import '../providers/customer_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/language_provider.dart';
import '../providers/sales_provider.dart';
import 'home/dashboard_screen.dart';
import 'madeni/madeni_screen.dart';
import 'mizigo/mizigo_screen.dart';
import 'profile/profile_screen.dart';
import 'wateja/wateja_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final inventory = context.watch<InventoryProvider>();
    final customers = context.watch<CustomerProvider>();
    final sales = context.watch<SalesProvider>();

    final mizigoBadge = inventory.totalMaguniaRemaining;
    final watejaCount = customers.customers.length;
    final madeniCount = DebtCalculator.computeAll(
      customers.customers,
      sales.sales,
      customers.payments,
    ).where((cd) => cd.hasDebt).length;

    final nav = _CustomBottomNav(
      currentIndex: _index,
      onTap: goToTab,
      lang: lang,
      mizigoBadge: mizigoBadge,
      watejaCount: watejaCount,
      madeniCount: madeniCount,
      vertical: Responsive.isTablet(context),
    );
    final body = IndexedStack(
      index: _index,
      children: const [
        DashboardScreen(),
        MizigoScreen(),
        WatejaScreen(),
        MadeniScreen(),
        ProfileScreen(),
      ],
    );

    // Tablets get the menu down the left side; phones keep it at the bottom.
    return MainShellController(
      goToTab: goToTab,
      child: Responsive.isTablet(context)
          ? Scaffold(body: Row(children: [nav, Expanded(child: body)]))
          : Scaffold(body: body, bottomNavigationBar: nav),
    );
  }
}

class _CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final LanguageProvider lang;
  final int mizigoBadge;
  final int watejaCount;
  final int madeniCount;
  final bool vertical;

  const _CustomBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.lang,
    required this.mizigoBadge,
    required this.watejaCount,
    required this.madeniCount,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: AmazingIconOutlined.home,
        label: lang.t('navHome'),
        isActive: currentIndex == 0,
        onTap: () => onTap(0),
      ),
      _NavItem(
        icon: AmazingIconOutlined.bag,
        label: lang.t('navMizigo'),
        isActive: currentIndex == 1,
        onTap: () => onTap(1),
        badge: mizigoBadge,
      ),
      _CenterButton(
        isActive: currentIndex == 2,
        onTap: () => onTap(2),
        icon: AmazingIconOutlined.people,
        label: lang.t('navWateja'),
        badge: watejaCount,
        showLabel: vertical,
      ),
      _NavItem(
        icon: AmazingIconOutlined.receipt,
        label: lang.t('navMadeni'),
        isActive: currentIndex == 3,
        onTap: () => onTap(3),
        badge: madeniCount,
      ),
      _NavItem(
        icon: AmazingIconOutlined.profile,
        label: lang.t('navProfile'),
        isActive: currentIndex == 4,
        onTap: () => onTap(4),
      ),
    ];

    final shadow = [
      BoxShadow(
        color: AppColors.deepBlue.withValues(alpha: 0.10),
        blurRadius: 24,
        offset: vertical ? const Offset(4, 0) : const Offset(0, -4),
      ),
    ];

    // Tablet: a rounded menu card floating on the left.
    if (vertical) {
      return SizedBox(
        width: Responsive.railWidth,
        child: SafeArea(
          right: false,
          child: Center(
            child: Container(
              width: Responsive.railWidth - 24,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: shadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 18,
                children: items,
              ),
            ),
          ),
        ),
      );
    }

    // Phone: a bar with rounded top corners. The Wateja button sits in a
    // raised circle above the bar; its label stays in the bar below it.
    const raise = _CenterButton.raisedSize / 2;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: raise),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: shadow,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    items[0],
                    items[1],
                    SizedBox(
                      width: 64,
                      child: Text(
                        lang.t('navWateja'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: currentIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                          color: currentIndex == 2 ? AppColors.deepBlue : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    items[3],
                    items[4],
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(top: 0, child: items[2]),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.deepBlue.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isActive ? AppColors.deepBlue : AppColors.textSecondary,
                  ),
                  if (badge != null && badge! > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.deepBlue : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  static const double raisedSize = 58;

  final bool isActive;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final int badge;
  final bool showLabel;

  const _CenterButton({
    required this.isActive,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.badge,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: raisedSize,
      height: raisedSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: AppColors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: isActive ? AppColors.amber : Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 26, color: isActive ? AppColors.amber : Colors.white),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          if (showLabel) ...[
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.deepBlue : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class MainShellController extends InheritedWidget {
  final void Function(int index) goToTab;

  const MainShellController({super.key, required this.goToTab, required super.child});

  static MainShellController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellController>();
  }

  @override
  bool updateShouldNotify(MainShellController oldWidget) => false;
}
