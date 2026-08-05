import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/app_colors.dart';
import '../../core/debt_calculator.dart';
import '../../core/formatters.dart';
import '../../models/sale.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quick_action_button.dart';
import '../../widgets/section_title.dart';
import '../../widgets/summary_card.dart';
import '../main_shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final inventory = context.watch<InventoryProvider>();
    final sales = context.watch<SalesProvider>();
    final customers = context.watch<CustomerProvider>();
    final settings = context.watch<SettingsProvider>();

    final totalDebt = DebtCalculator.totalOutstanding(customers.customers, sales.sales, customers.payments);
    final recentSales = sales.sales.take(5).toList();
    final shell = MainShellController.maybeOf(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.deepBlue,
            expandedHeight: 96,
            actions: [
              IconButton(
                icon: const Icon(AmazingIconOutlined.profile, size: 22),
                onPressed: () => shell?.goToTab(4),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14, right: 16),
              title: Text(
                settings.profile.businessName,
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('${lang.t('greeting')}, ${settings.profile.ownerName} 👋', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    SummaryCard(
                      label: lang.t('totalStock'),
                      value: '${inventory.totalMaguniaRemaining} ${lang.t('magunia')}',
                      subtitle: AppFormatters.money(inventory.remainingStockValue),
                      icon: AmazingIconOutlined.bag,
                      accentColor: AppColors.deepBlue,
                      onTap: () => shell?.goToTab(1),
                    ),
                    SummaryCard(
                      label: lang.t('salesToday'),
                      value: AppFormatters.money(sales.totalRevenueToday),
                      subtitle: '${sales.today.length} ${lang.t('entries')}',
                      icon: AmazingIconOutlined.moneyRecive,
                      accentColor: AppColors.amberDark,
                      onTap: () => shell?.goToTab(1),
                    ),
                    SummaryCard(
                      label: lang.t('outstandingDebts'),
                      value: AppFormatters.money(totalDebt),
                      subtitle: totalDebt > 0 ? lang.t('debtors') : lang.t('allSettled'),
                      icon: AmazingIconOutlined.receipt,
                      accentColor: totalDebt > 0 ? AppColors.danger : AppColors.success,
                      onTap: () => shell?.goToTab(3),
                    ),
                    SummaryCard(
                      label: lang.t('customers'),
                      value: '${customers.customers.length}',
                      icon: AmazingIconOutlined.people,
                      accentColor: AppColors.deepBlueLight,
                      onTap: () => shell?.goToTab(2),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionTitle(title: lang.t('quickActions')),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuickActionButton(icon: AmazingIconOutlined.boxAdd, label: lang.t('addStock'), onTap: () => shell?.goToTab(1)),
                    QuickActionButton(icon: AmazingIconOutlined.moneyRecive, label: lang.t('recordSale'), onTap: () => shell?.goToTab(1)),
                    QuickActionButton(icon: AmazingIconOutlined.userAdd, label: lang.t('addCustomer'), onTap: () => shell?.goToTab(2)),
                    QuickActionButton(icon: AmazingIconOutlined.receipt, label: lang.t('viewReports'), onTap: () => shell?.goToTab(3)),
                  ],
                ),
                const SizedBox(height: 24),
                SectionTitle(title: lang.t('recentSales'), actionLabel: lang.t('seeAll'), onAction: () => shell?.goToTab(1)),
                const SizedBox(height: 8),
                if (recentSales.isEmpty)
                  EmptyState(icon: AmazingIconOutlined.receipt, message: lang.t('noRecentSales'))
                else
                  Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < recentSales.length; i++) ...[
                          _RecentSaleTile(sale: recentSales[i], lang: lang),
                          if (i != recentSales.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  final Sale sale;
  final LanguageProvider lang;

  const _RecentSaleTile({required this.sale, required this.lang});

  @override
  Widget build(BuildContext context) {
    final createsDebt = sale.paymentType == PaymentType.credit || sale.paymentType == PaymentType.partial;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: (createsDebt ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
        child: Icon(createsDebt ? AmazingIconOutlined.clock : AmazingIconOutlined.tickCircle, color: createsDebt ? AppColors.danger : AppColors.success, size: 20),
      ),
      title: Text(sale.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('${sale.magunia} ${lang.t('magunia')} • ${AppFormatters.dateShort(sale.date)}', style: const TextStyle(fontSize: 12)),
      trailing: Text(AppFormatters.money(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
    );
  }
}
