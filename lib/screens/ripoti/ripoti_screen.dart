import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/debt_calculator.dart';
import '../../core/formatters.dart';
import '../../models/sale.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_title.dart';

class RipotiScreen extends StatelessWidget {
  const RipotiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final salesProvider = context.watch<SalesProvider>();
    final inventory = context.watch<InventoryProvider>();
    final customerProvider = context.watch<CustomerProvider>();

    double costOf(Sale s) => s.magunia * (inventory.byId(s.stockItemId)?.purchasePricePerBag ?? s.pricePerBag * 0.8);

    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final dailyRevenue = <double>[];
    double weekRevenue = 0;
    double weekCost = 0;
    for (final day in last7Days) {
      final daySales = salesProvider.sales.where((s) => s.date.year == day.year && s.date.month == day.month && s.date.day == day.day);
      final dayTotal = daySales.fold(0.0, (sum, s) => sum + s.totalAmount);
      final dayCost = daySales.fold(0.0, (sum, s) => sum + costOf(s));
      dailyRevenue.add(dayTotal);
      weekRevenue += dayTotal;
      weekCost += dayCost;
    }
    final weekProfit = weekRevenue - weekCost;

    final topDebtors = DebtCalculator.computeAll(customerProvider.customers, salesProvider.sales, customerProvider.payments)
        .where((cd) => cd.hasDebt)
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    final top5 = topDebtors.take(5).toList();

    final maxRevenue = dailyRevenue.fold<double>(0, (m, v) => v > m ? v : m);

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('ripotiTitle'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Responsive.sidePadding(context), 16, Responsive.sidePadding(context), 24),
        children: [
          SectionTitle(title: '${lang.t('profitSummary')} • ${lang.t('last7Days')}'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MetricCard(label: lang.t('totalRevenue'), value: AppFormatters.money(weekRevenue), color: AppColors.deepBlue)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: lang.t('totalCost'), value: AppFormatters.money(weekCost), color: AppColors.textSecondary)),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(label: lang.t('totalProfit'), value: AppFormatters.money(weekProfit), color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(title: '${lang.t('salesTrend')} • ${lang.t('last7Days')}'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
              child: SizedBox(
                height: 190,
                child: maxRevenue <= 0
                    ? EmptyState(icon: AmazingIconOutlined.chart, message: lang.t('noSales'))
                    : BarChart(
                        BarChartData(
                          maxY: maxRevenue * 1.25,
                          alignment: BarChartAlignment.spaceAround,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= last7Days.length) return const SizedBox.shrink();
                                  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(weekdays[last7Days[idx].weekday - 1], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (int i = 0; i < dailyRevenue.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: dailyRevenue[i],
                                    color: i == dailyRevenue.length - 1 ? AppColors.amber : AppColors.deepBlue,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle(title: lang.t('topDebtors')),
          const SizedBox(height: 12),
          if (top5.isEmpty)
            EmptyState(icon: AmazingIconOutlined.award, message: lang.t('noDebts'))
          else
            Card(
              child: Column(
                children: [
                  for (int i = 0; i < top5.length; i++) ...[
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                        child: Text('${i + 1}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(top5[i].customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(top5[i].customer.phone, style: const TextStyle(fontSize: 12)),
                      trailing: Text(AppFormatters.money(top5[i].balance), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                    ),
                    if (i != top5.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
