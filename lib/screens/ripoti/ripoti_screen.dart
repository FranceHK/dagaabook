import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/debt_calculator.dart';
import '../../core/formatters.dart';
import '../../models/payment.dart';
import '../../models/sale.dart';
import '../../models/stock_item.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_title.dart';
import '../../widgets/summary_card.dart';

enum _Period { today, week, month, all }

/// One bar in the sales chart: a day, or a month for the all-time view.
class _Bucket {
  final String label;
  final DateTime start;
  final DateTime end;
  double revenue = 0;
  double profit = 0;

  _Bucket(this.label, this.start, this.end);

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
}

/// Everything about the business in one place: money in and out, profit,
/// debts, stock, customers and mobile money transactions for a chosen period.
class RipotiScreen extends StatefulWidget {
  const RipotiScreen({super.key});

  @override
  State<RipotiScreen> createState() => _RipotiScreenState();
}

class _RipotiScreenState extends State<RipotiScreen> {
  _Period _period = _Period.week;

  static const _weekdaysSw = ['Jtt', 'Jnn', 'Jtn', 'Alh', 'Ijm', 'Jms', 'Jpl'];
  static const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthsSw = ['Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  DateTime _periodStart(DateTime today) => switch (_period) {
        _Period.today => today,
        _Period.week => today.subtract(const Duration(days: 6)),
        _Period.month => DateTime(today.year, today.month),
        _Period.all => DateTime(2000),
      };

  List<_Bucket> _buckets(DateTime today, bool sw) {
    final weekdays = sw ? _weekdaysSw : _weekdaysEn;
    final months = sw ? _monthsSw : _monthsEn;
    _Bucket day(DateTime d, String label) => _Bucket(label, d, d.add(const Duration(days: 1)));

    switch (_period) {
      case _Period.today:
      case _Period.week:
        return [
          for (int i = 6; i >= 0; i--)
            day(today.subtract(Duration(days: i)), weekdays[today.subtract(Duration(days: i)).weekday - 1]),
        ];
      case _Period.month:
        return [
          for (int d = 1; d <= today.day; d++) day(DateTime(today.year, today.month, d), '$d'),
        ];
      case _Period.all:
        return [
          for (int i = 11; i >= 0; i--)
            _Bucket(
              months[DateTime(today.year, today.month - i).month - 1],
              DateTime(today.year, today.month - i),
              DateTime(today.year, today.month - i + 1),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final allSales = context.watch<SalesProvider>().sales;
    final inventory = context.watch<InventoryProvider>();
    final customerProvider = context.watch<CustomerProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = _periodStart(today);
    bool inPeriod(DateTime d) => !d.isBefore(start);

    final sales = allSales.where((s) => inPeriod(s.date)).toList();
    final payments = customerProvider.payments.where((p) => inPeriod(p.date)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double costOf(Sale s) => s.magunia * (inventory.byId(s.stockItemId)?.purchasePricePerBag ?? s.pricePerBag);
    double profitOf(Sale s) => s.totalAmount - costOf(s);

    final revenue = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final cost = sales.fold(0.0, (sum, s) => sum + costOf(s));
    final profit = revenue - cost;
    final bagsSold = sales.fold(0, (sum, s) => sum + s.magunia);
    final newDebt = sales.fold(0.0, (sum, s) => sum + s.outstanding);
    final debtPaid = payments.fold(0.0, (sum, p) => sum + p.amount);

    // Money received, split by cash and mobile money.
    double cashIn = 0;
    double mobileIn = 0;
    for (final s in sales) {
      final viaPhone = s.paymentType == PaymentType.mobile || s.transactionId.isNotEmpty;
      if (viaPhone) {
        mobileIn += s.amountPaid;
      } else {
        cashIn += s.amountPaid;
      }
    }
    for (final p in payments) {
      if (p.isMobile) {
        mobileIn += p.amount;
      } else {
        cashIn += p.amount;
      }
    }

    final byType = <PaymentType, double>{for (final t in PaymentType.values) t: 0};
    for (final s in sales) {
      byType[s.paymentType] = byType[s.paymentType]! + s.totalAmount;
    }

    final buckets = _buckets(today, lang.isSwahili);
    for (final s in allSales) {
      for (final b in buckets) {
        if (b.contains(s.date)) {
          b.revenue += s.totalAmount;
          b.profit += profitOf(s);
        }
      }
    }

    // Profit per dagaa type.
    final typeRows = <String, ({int bags, double revenue, double profit})>{};
    for (final s in sales) {
      final row = typeRows[s.stockType] ?? (bags: 0, revenue: 0.0, profit: 0.0);
      typeRows[s.stockType] = (bags: row.bags + s.magunia, revenue: row.revenue + s.totalAmount, profit: row.profit + profitOf(s));
    }
    final typeList = typeRows.entries.toList()..sort((a, b) => b.value.profit.compareTo(a.value.profit));

    // Best buyers in the period.
    final buyers = <String, double>{};
    for (final s in sales) {
      buyers[s.customerName] = (buyers[s.customerName] ?? 0) + s.totalAmount;
    }
    final topBuyers = buyers.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final debts = DebtCalculator.computeAll(customerProvider.customers, allSales, customerProvider.payments)
        .where((cd) => cd.hasDebt)
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    final totalDebt = debts.fold(0.0, (sum, d) => sum + d.balance);

    final mobileTx = <({String id, String who, double amount, DateTime date, bool isDebtPayment})>[
      for (final s in sales)
        if (s.transactionId.isNotEmpty) (id: s.transactionId, who: s.customerName, amount: s.amountPaid, date: s.date, isDebtPayment: false),
      for (final p in payments)
        if (p.transactionId.isNotEmpty)
          (id: p.transactionId, who: customerProvider.byId(p.customerId)?.name ?? '-', amount: p.amount, date: p.date, isDebtPayment: true),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final tablet = Responsive.isTablet(context);
    final pad = Responsive.sidePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('ripotiTitle'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _Period.values)
                ChoiceChip(
                  label: Text(lang.t(switch (p) {
                    _Period.today => 'today',
                    _Period.week => 'last7Days',
                    _Period.month => 'thisMonth',
                    _Period.all => 'allTime',
                  })),
                  selected: _period == p,
                  onSelected: (_) => setState(() => _period = p),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: tablet ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 136,
            ),
            children: [
              SummaryCard(label: lang.t('totalRevenue'), value: AppFormatters.money(revenue), subtitle: '${sales.length} ${lang.t('salesCount')}', icon: AmazingIconOutlined.moneyRecive),
              SummaryCard(label: lang.t('totalCost'), value: AppFormatters.money(cost), subtitle: '$bagsSold ${lang.t('magunia')}', icon: AmazingIconOutlined.bag, accentColor: AppColors.textSecondary),
              SummaryCard(label: lang.t('totalProfit'), value: AppFormatters.money(profit), subtitle: revenue > 0 ? '${(profit / revenue * 100).toStringAsFixed(1)}%' : null, icon: AmazingIconOutlined.trendUp, accentColor: profit < 0 ? AppColors.danger : AppColors.success),
              SummaryCard(label: lang.t('cashIn'), value: AppFormatters.money(cashIn + mobileIn), subtitle: '${lang.t('debtPayments')}: ${AppFormatters.money(debtPaid)}', icon: AmazingIconOutlined.wallet, accentColor: AppColors.amberDark),
              SummaryCard(label: lang.t('newDebts'), value: AppFormatters.money(newDebt), icon: AmazingIconOutlined.clock, accentColor: AppColors.danger),
              SummaryCard(label: lang.t('totalOwed'), value: AppFormatters.money(totalDebt), subtitle: '${debts.length} ${lang.t('debtors')}', icon: AmazingIconOutlined.receipt, accentColor: AppColors.danger),
              SummaryCard(label: lang.t('remainingBags'), value: '${inventory.totalMaguniaRemaining} ${lang.t('magunia')}', subtitle: AppFormatters.money(inventory.remainingStockValue), icon: AmazingIconOutlined.box, accentColor: AppColors.deepBlueLight),
              SummaryCard(label: lang.t('mobileMoney'), value: AppFormatters.money(mobileIn), subtitle: '${lang.t('cash')}: ${AppFormatters.money(cashIn)}', icon: AmazingIconOutlined.mobile, accentColor: AppColors.deepBlue),
            ],
          ),
          const SizedBox(height: 24),
          SectionTitle(title: lang.t('salesTrend')),
          const SizedBox(height: 8),
          _ChartCard(buckets: buckets, lang: lang),
          const SizedBox(height: 24),
          _TwoUp(
            tablet: tablet,
            left: _Section(
              title: lang.t('byPaymentType'),
              child: _BreakdownCard(rows: [
                (label: lang.t('cash'), value: byType[PaymentType.cash]!, color: AppColors.success),
                (label: lang.t('mobile'), value: byType[PaymentType.mobile]!, color: AppColors.deepBlue),
                (label: lang.t('partial'), value: byType[PaymentType.partial]!, color: AppColors.amberDark),
                (label: lang.t('credit'), value: byType[PaymentType.credit]!, color: AppColors.danger),
              ]),
            ),
            right: _Section(
              title: lang.t('moneyReceived'),
              child: _BreakdownCard(rows: [
                (label: lang.t('cash'), value: cashIn, color: AppColors.success),
                (label: lang.t('mobile'), value: mobileIn, color: AppColors.deepBlue),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: lang.t('profitByType'),
            child: typeList.isEmpty
                ? _EmptyCard(message: lang.t('noData'))
                : Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < typeList.length; i++) ...[
                          ListTile(
                            title: Text(typeList[i].key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('${typeList[i].value.bags} ${lang.t('magunia')} • ${AppFormatters.money(typeList[i].value.revenue)}', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              AppFormatters.money(typeList[i].value.profit),
                              style: TextStyle(fontWeight: FontWeight.bold, color: typeList[i].value.profit < 0 ? AppColors.danger : AppColors.success),
                            ),
                          ),
                          if (i != typeList.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: lang.t('stockStatus'),
            child: inventory.items.isEmpty
                ? _EmptyCard(message: lang.t('noStock'))
                : Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < inventory.items.length; i++) ...[
                          _StockRow(item: inventory.items[i], profitEarned: inventory.items[i].profitEarned(allSales), lang: lang),
                          if (i != inventory.items.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          _TwoUp(
            tablet: tablet,
            left: _Section(
              title: lang.t('topCustomers'),
              child: topBuyers.isEmpty
                  ? _EmptyCard(message: lang.t('noData'))
                  : _RankCard(rows: [for (final b in topBuyers.take(5)) (name: b.key, detail: '', amount: b.value)], color: AppColors.deepBlue),
            ),
            right: _Section(
              title: lang.t('topDebtors'),
              child: debts.isEmpty
                  ? _EmptyCard(message: lang.t('noDebts'))
                  : _RankCard(rows: [for (final d in debts.take(5)) (name: d.customer.name, detail: d.customer.phone, amount: d.balance)], color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: '${lang.t('mobileTransactions')} (${mobileTx.length})',
            child: mobileTx.isEmpty
                ? _EmptyCard(message: lang.t('noData'))
                : Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < mobileTx.length; i++) ...[
                          ListTile(
                            dense: true,
                            leading: const Icon(AmazingIconOutlined.mobile, color: AppColors.deepBlue, size: 20),
                            title: SelectableText(mobileTx[i].id, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            subtitle: Text(
                              '${mobileTx[i].who} • ${AppFormatters.dateShort(mobileTx[i].date)}'
                              '${mobileTx[i].isDebtPayment ? ' • ${lang.t('debtPayments')}' : ''}',
                            ),
                            trailing: Text(AppFormatters.money(mobileTx[i].amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          if (i != mobileTx.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          _TwoUp(
            tablet: tablet,
            left: _Section(
              title: '${lang.t('periodSales')} (${sales.length})',
              child: sales.isEmpty
                  ? _EmptyCard(message: lang.t('noSales'))
                  : Card(
                      child: Column(
                        children: [
                          for (int i = 0; i < sales.length; i++) ...[
                            ListTile(
                              dense: true,
                              title: Text(sales[i].customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${sales[i].stockType} • ${sales[i].magunia} ${lang.t('magunia')} • ${AppFormatters.dateShort(sales[i].date)}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(AppFormatters.money(sales[i].totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${lang.t('profit')}: ${AppFormatters.money(profitOf(sales[i]))}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ),
                            if (i != sales.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                        ],
                      ),
                    ),
            ),
            right: _Section(
              title: '${lang.t('debtPayments')} (${payments.length})',
              child: payments.isEmpty
                  ? _EmptyCard(message: lang.t('noData'))
                  : Card(
                      child: Column(
                        children: [
                          for (int i = 0; i < payments.length; i++) ...[
                            _PaymentRow(payment: payments[i], name: customerProvider.byId(payments[i].customerId)?.name ?? '-', lang: lang),
                            if (i != payments.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Side by side on tablets, stacked on phones.
class _TwoUp extends StatelessWidget {
  final bool tablet;
  final Widget left;
  final Widget right;

  const _TwoUp({required this.tablet, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    if (!tablet) return Column(children: [left, const SizedBox(height: 24), right]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: left), const SizedBox(width: 16), Expanded(child: right)],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [SectionTitle(title: title), const SizedBox(height: 8), child],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<_Bucket> buckets;
  final LanguageProvider lang;

  const _ChartCard({required this.buckets, required this.lang});

  @override
  Widget build(BuildContext context) {
    final maxY = buckets.fold<double>(0, (m, b) => b.revenue > m ? b.revenue : m);
    // Show every label when there are few bars; thin them out for a month.
    final labelEvery = buckets.length > 14 ? 5 : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                _Legend(color: AppColors.deepBlue, label: lang.t('revenue')),
                const SizedBox(width: 16),
                _Legend(color: AppColors.amber, label: lang.t('profit')),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: maxY <= 0
                  ? EmptyState(icon: AmazingIconOutlined.chart, message: lang.t('noSales'))
                  : BarChart(
                      BarChartData(
                        maxY: maxY * 1.2,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                              AppFormatters.money(rod.toY),
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                                if (i % labelEvery != 0 && i != buckets.length - 1) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(buckets[i].label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (int i = 0; i < buckets.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 2,
                              barRods: [
                                BarChartRodData(toY: buckets[i].revenue, color: AppColors.deepBlue, width: buckets.length > 14 ? 4 : 12, borderRadius: BorderRadius.circular(3)),
                                BarChartRodData(toY: buckets[i].profit < 0 ? 0 : buckets[i].profit, color: AppColors.amber, width: buckets.length > 14 ? 4 : 12, borderRadius: BorderRadius.circular(3)),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final List<({String label, double value, Color color})> rows;

  const _BreakdownCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final total = rows.fold(0.0, (sum, r) => sum + r.value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final r in rows) ...[
              Row(
                children: [
                  Expanded(child: Text(r.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text(AppFormatters.money(r.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? r.value / total : 0,
                  minHeight: 6,
                  color: r.color,
                  backgroundColor: AppColors.divider,
                ),
              ),
              if (r != rows.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final List<({String name, String detail, double amount})> rows;
  final Color color;

  const _RankCard({required this.rows, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              title: Text(rows[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: rows[i].detail.isEmpty ? null : Text(rows[i].detail),
              trailing: Text(AppFormatters.money(rows[i].amount), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final StockItem item;
  final double profitEarned;
  final LanguageProvider lang;

  const _StockRow({required this.item, required this.profitEarned, required this.lang});

  @override
  Widget build(BuildContext context) {
    final sold = item.totalMagunia == 0 ? 0.0 : item.soldMagunia / item.totalMagunia;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              Text('${item.remainingMagunia} / ${item.totalMagunia} ${lang.t('magunia')}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: sold, minHeight: 6, color: AppColors.amber, backgroundColor: AppColors.divider),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text('${lang.t('profitPerBag')}: ${AppFormatters.money(item.profitPerBag)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                '${lang.t('profitEarned')}: ${AppFormatters.money(profitEarned)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: profitEarned < 0 ? AppColors.danger : AppColors.success),
              ),
              Text('${lang.t('profitExpected')}: ${AppFormatters.money(item.remainingMagunia * item.profitPerBag)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  final String name;
  final LanguageProvider lang;

  const _PaymentRow({required this.payment, required this.name, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(payment.isMobile ? AmazingIconOutlined.mobile : AmazingIconOutlined.wallet, color: AppColors.success, size: 20),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        AppFormatters.dateShort(payment.date),
        if (payment.transactionId.isNotEmpty) '${lang.t('transactionShort')}: ${payment.transactionId}',
        if (payment.note.isNotEmpty) payment.note,
      ].join(' • ')),
      trailing: Text(AppFormatters.money(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
    );
  }
}
