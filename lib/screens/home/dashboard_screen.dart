import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/debt_calculator.dart';
import '../../core/formatters.dart';
import '../../models/sale.dart';
import '../../models/stock_item.dart';
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
import '../profile/edit_profile_sheet.dart';
import '../ripoti/ripoti_screen.dart';
import '../mauzo/mauzo_screen.dart';

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
                tooltip: lang.t('ripotiTitle'),
                icon: const Icon(AmazingIconOutlined.chart, size: 22),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RipotiScreen())),
              ),
              IconButton(
                icon: const Icon(AmazingIconOutlined.profile, size: 22),
                onPressed: () => shell?.goToTab(4),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: Responsive.sidePadding(context), bottom: 14, right: 16),
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
            padding: EdgeInsets.fromLTRB(Responsive.sidePadding(context), 16, Responsive.sidePadding(context), 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _OwnerCard(
                  greeting: lang.t('greeting'),
                  name: settings.profile.ownerName,
                  phone: settings.profile.phone,
                  editLabel: lang.t('edit'),
                ),
                const SizedBox(height: 16),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.isTablet(context) ? 4 : 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 136,
                  ),
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
                  mainAxisAlignment: Responsive.isTablet(context) ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.spaceBetween,
                  children: [
                    QuickActionButton(icon: AmazingIconOutlined.boxAdd, label: lang.t('addStock'), onTap: () => shell?.goToTab(1)),
                    QuickActionButton(icon: AmazingIconOutlined.moneyRecive, label: lang.t('recordSale'), onTap: () => shell?.goToTab(1)),
                    QuickActionButton(icon: AmazingIconOutlined.userAdd, label: lang.t('addCustomer'), onTap: () => shell?.goToTab(2)),
                    QuickActionButton(icon: AmazingIconOutlined.chart, label: lang.t('viewReports'), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RipotiScreen()))),
                  ],
                ),
                const SizedBox(height: 24),
                SectionTitle(title: lang.t('recentStock'), actionLabel: lang.t('seeAll'), onAction: () => shell?.goToTab(1)),
                const SizedBox(height: 8),
                if (inventory.items.isEmpty)
                  EmptyState(icon: AmazingIconOutlined.box, message: lang.t('noStock'))
                else
                  Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Row(
                            children: [
                              const Icon(AmazingIconOutlined.box, size: 18, color: AppColors.deepBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${lang.t('inStore')}: ${inventory.totalMaguniaRemaining} ${lang.t('magunia')}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                              Text(AppFormatters.money(inventory.remainingStockValue), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.amberDark)),
                            ],
                          ),
                        ),
                        for (final item in inventory.items.take(4)) ...[
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _RecentStockTile(item: item, lang: lang),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SectionTitle(title: lang.t('recentSales'), actionLabel: lang.t('seeAll'), onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MauzoScreen()))),
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

/// Greets the owner and lets them fix their name and phone right from the
/// dashboard.
class _OwnerCard extends StatelessWidget {
  final String greeting;
  final String name;
  final String phone;
  final String editLabel;

  const _OwnerCard({required this.greeting, required this.name, required this.phone, required this.editLabel});

  @override
  Widget build(BuildContext context) {
    void openEditor() => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const EditProfileSheet(),
        );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: openEditor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.amber,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting 👋', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (phone.isNotEmpty)
                      Text(phone, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: openEditor,
                icon: const Icon(AmazingIconOutlined.edit, size: 18),
                label: Text(editLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentStockTile extends StatelessWidget {
  final StockItem item;
  final LanguageProvider lang;

  const _RecentStockTile({required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    final soldOut = item.isSoldOut;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(
                soldOut ? lang.t('soldOut') : '${item.remainingMagunia} / ${item.totalMagunia} ${lang.t('magunia')}',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: soldOut ? AppColors.danger : AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.totalMagunia == 0 ? 0 : item.remainingMagunia / item.totalMagunia,
              minHeight: 5,
              color: soldOut ? AppColors.danger : AppColors.deepBlue,
              backgroundColor: AppColors.divider,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppFormatters.dateShort(item.dateAdded)} • ${lang.t('profitPerBag')}: ${AppFormatters.money(item.profitPerBag)}',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
