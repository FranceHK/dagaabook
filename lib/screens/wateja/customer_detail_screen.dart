import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/debt_calculator.dart';
import '../../core/formatters.dart';
import '../../models/customer.dart';
import '../../models/payment.dart';
import '../../models/sale.dart';
import '../../providers/customer_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_title.dart';
import '../../widgets/summary_card.dart';
import '../madeni/record_payment_sheet.dart';
import 'add_customer_sheet.dart';

enum _HistoryFilter { all, purchases, payments }

/// Everything that happened with one customer on one day.
class _Day {
  final DateTime date;
  final List<Sale> sales = [];
  final List<Payment> payments = [];

  /// Debt left at the end of this day, after all earlier days.
  double balanceAfter = 0;

  _Day(this.date);

  double get bought => sales.fold(0.0, (sum, s) => sum + s.totalAmount);
  double get paid => sales.fold(0.0, (sum, s) => sum + s.amountPaid) + payments.fold(0.0, (sum, p) => sum + p.amount);
}

/// One customer's full story: what they owe, what they bought, and a
/// day-by-day history of purchases and payments.
class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Groups purchases and payments by day and works out the debt left at
  /// the end of each day. Newest day first.
  static List<_Day> _buildDays(List<Sale> sales, List<Payment> payments) {
    final days = <DateTime, _Day>{};
    for (final s in sales) {
      days.putIfAbsent(_dayOf(s.date), () => _Day(_dayOf(s.date))).sales.add(s);
    }
    for (final p in payments) {
      days.putIfAbsent(_dayOf(p.date), () => _Day(_dayOf(p.date))).payments.add(p);
    }
    final ordered = days.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    var balance = 0.0;
    for (final day in ordered) {
      balance += day.sales.fold(0.0, (sum, s) => sum + s.outstanding);
      balance -= day.payments.fold(0.0, (sum, p) => sum + p.amount);
      day.balanceAfter = balance < 0 ? 0 : balance;
      day.sales.sort((a, b) => b.date.compareTo(a.date));
      day.payments.sort((a, b) => b.date.compareTo(a.date));
    }
    return ordered.reversed.toList();
  }

  /// Date of the oldest purchase not yet covered by debt payments, paying
  /// off the oldest debts first.
  static DateTime? _oldestUnpaid(List<Sale> sales, List<Payment> payments) {
    var paidPool = payments.fold(0.0, (sum, p) => sum + p.amount);
    final ordered = sales.where((s) => s.outstanding > 0).toList()..sort((a, b) => a.date.compareTo(b.date));
    for (final s in ordered) {
      if (paidPool >= s.outstanding) {
        paidPool -= s.outstanding;
      } else {
        return s.date;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final salesProvider = context.watch<SalesProvider>();
    // Read the latest copy so edits show straight away.
    final customer = customerProvider.byId(widget.customer.id) ?? widget.customer;

    final sales = salesProvider.salesForCustomer(customer.id);
    final payments = customerProvider.paymentsForCustomer(customer.id);
    final balance = DebtCalculator.balanceFor(customer.id, salesProvider.sales, customerProvider.payments);
    final totalPurchased = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final paidAtSale = sales.fold(0.0, (sum, s) => sum + s.amountPaid);
    final debtPaid = payments.fold(0.0, (sum, p) => sum + p.amount);
    final debtFromPurchases = sales.fold(0.0, (sum, s) => sum + s.outstanding);
    final boxes = sales.fold(0, (sum, s) => sum + s.magunia);
    final oldestUnpaid = balance > 0 ? _oldestUnpaid(sales, payments) : null;

    final products = <String, ({int boxes, double amount, int times})>{};
    for (final s in sales) {
      final p = products[s.stockType] ?? (boxes: 0, amount: 0.0, times: 0);
      products[s.stockType] = (boxes: p.boxes + s.magunia, amount: p.amount + s.totalAmount, times: p.times + 1);
    }
    final productList = products.entries.toList()..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    final days = _buildDays(sales, payments).where((d) => switch (_filter) {
          _HistoryFilter.all => true,
          _HistoryFilter.purchases => d.sales.isNotEmpty,
          _HistoryFilter.payments => d.payments.isNotEmpty,
        });

    final tablet = Responsive.isTablet(context);
    final pad = Responsive.sidePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('customerDetail')),
        actions: [
          IconButton(
            tooltip: lang.t('edit'),
            icon: const Icon(AmazingIconOutlined.edit),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddCustomerSheet(customer: customer),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _Header(customer: customer, balance: balance, lang: lang),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    SummaryCard(
                      label: lang.t('totalPurchased'),
                      value: AppFormatters.money(totalPurchased),
                      subtitle: '${sales.length} ${lang.t('purchasesCount')}',
                      icon: AmazingIconOutlined.shoppingCart,
                    ),
                    SummaryCard(
                      label: lang.t('totalPaid'),
                      value: AppFormatters.money(paidAtSale + debtPaid),
                      subtitle: '${payments.length} ${lang.t('debtPayments').toLowerCase()}',
                      icon: AmazingIconOutlined.wallet,
                      accentColor: AppColors.success,
                    ),
                    SummaryCard(
                      label: lang.t('balance'),
                      value: AppFormatters.money(balance),
                      subtitle: balance > 0 ? lang.t('owes') : lang.t('noDebt'),
                      icon: AmazingIconOutlined.receipt,
                      accentColor: balance > 0 ? AppColors.danger : AppColors.success,
                    ),
                    SummaryCard(
                      label: lang.t('boxesBought'),
                      value: '$boxes ${lang.t('magunia')}',
                      subtitle: sales.isEmpty ? null : '${lang.t('lastPurchase')}: ${AppFormatters.dateShort(sales.first.date)}',
                      icon: AmazingIconOutlined.box,
                      accentColor: AppColors.amberDark,
                    ),
                  ],
                ),
                if (balance > 0) ...[
                  const SizedBox(height: 16),
                  _DebtCard(
                    balance: balance,
                    debtFromPurchases: debtFromPurchases,
                    debtPaid: debtPaid,
                    oldestUnpaid: oldestUnpaid,
                    lang: lang,
                  ),
                ],
                const SizedBox(height: 24),
                SectionTitle(title: lang.t('productsBought')),
                const SizedBox(height: 8),
                if (productList.isEmpty)
                  _EmptyCard(message: lang.t('noHistory'))
                else
                  Card(
                    child: Column(
                      children: [
                        for (int i = 0; i < productList.length; i++) ...[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                              child: const Icon(AmazingIconOutlined.box, color: AppColors.amberDark, size: 20),
                            ),
                            title: Text(productList[i].key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(
                              '${productList[i].value.boxes} ${lang.t('magunia')} • ${productList[i].value.times} ${lang.t('times')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(AppFormatters.money(productList[i].value.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          if (i != productList.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SectionTitle(title: lang.t('dailyHistory')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in _HistoryFilter.values)
                      ChoiceChip(
                        label: Text(lang.t(switch (f) {
                          _HistoryFilter.all => 'all',
                          _HistoryFilter.purchases => 'purchases',
                          _HistoryFilter.payments => 'payments',
                        })),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (days.isEmpty)
                  EmptyState(icon: AmazingIconOutlined.receipt, message: lang.t('noHistory'))
                else
                  for (final day in days)
                    _DayCard(
                      day: day,
                      showSales: _filter != _HistoryFilter.payments,
                      showPayments: _filter != _HistoryFilter.purchases,
                      lang: lang,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Customer customer;
  final double balance;
  final LanguageProvider lang;

  const _Header({required this.customer, required this.balance, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: Responsive.sidePadding(context, min: 20), vertical: 20),
      color: AppColors.deepBlue,
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.amber,
            child: Text(
              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
            ),
          ),
          const SizedBox(height: 10),
          Text(customer.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (customer.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(customer.phone, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
          if (customer.location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(customer.location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lang.t('call')}: ${customer.phone}')));
                },
                icon: const Icon(AmazingIconOutlined.call, size: 16),
                label: Text(lang.t('call')),
              ),
              if (balance > 0)
                ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => RecordPaymentSheet(customer: customer, currentBalance: balance),
                  ),
                  icon: const Icon(AmazingIconOutlined.wallet, size: 16),
                  label: Text(lang.t('recordPayment')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final double balance;
  final double debtFromPurchases;
  final double debtPaid;
  final DateTime? oldestUnpaid;
  final LanguageProvider lang;

  const _DebtCard({
    required this.balance,
    required this.debtFromPurchases,
    required this.debtPaid,
    required this.oldestUnpaid,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500))),
              Text(value, style: TextStyle(fontSize: bold ? 16 : 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );

    final daysOld = oldestUnpaid == null ? null : DateTime.now().difference(oldestUnpaid!).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AmazingIconOutlined.danger, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              Text('${lang.t('owes')} ${AppFormatters.money(balance)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 10),
          row(lang.t('debtFromPurchases'), AppFormatters.money(debtFromPurchases)),
          row(lang.t('debtPayments'), '− ${AppFormatters.money(debtPaid)}', color: AppColors.success),
          const Divider(height: 14),
          row(lang.t('balance'), AppFormatters.money(balance), color: AppColors.danger, bold: true),
          if (oldestUnpaid != null) ...[
            const SizedBox(height: 8),
            Text(
              '${lang.t('oldestDebt')}: ${AppFormatters.date(oldestUnpaid!)} '
              '(${daysOld == 0 ? lang.t('today').toLowerCase() : lang.t('daysAgo').replaceAll('{n}', '$daysOld')})',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
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

class _DayCard extends StatelessWidget {
  final _Day day;
  final bool showSales;
  final bool showPayments;
  final LanguageProvider lang;

  const _DayCard({required this.day, required this.showSales, required this.showPayments, required this.lang});

  String _dayLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day.date == today) return lang.t('today');
    if (day.date == today.subtract(const Duration(days: 1))) return lang.t('yesterday');
    return AppFormatters.date(day.date);
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (showSales) for (final s in day.sales) _SaleRow(sale: s, lang: lang),
      if (showPayments) for (final p in day.payments) _PaymentRow(payment: p, lang: lang),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppColors.deepBlue.withValues(alpha: 0.05),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(AmazingIconOutlined.calendar, size: 16, color: AppColors.deepBlue),
                      const SizedBox(width: 6),
                      Text(_dayLabel(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.deepBlue)),
                    ],
                  ),
                  Text(
                    '${lang.t('bought')}: ${AppFormatters.money(day.bought)} • ${lang.t('paid')}: ${AppFormatters.money(day.paid)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${lang.t('debtEndOfDay')}: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    AppFormatters.money(day.balanceAfter),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: day.balanceAfter > 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  final Sale sale;
  final LanguageProvider lang;

  const _SaleRow({required this.sale, required this.lang});

  static final _time = DateFormat('HH:mm');

  String _typeLabel() => switch (sale.paymentType) {
        PaymentType.cash => lang.t('cash'),
        PaymentType.mobile => lang.t('mobile'),
        PaymentType.credit => lang.t('credit'),
        PaymentType.partial => lang.t('partial'),
      };

  @override
  Widget build(BuildContext context) {
    final owes = sale.outstanding > 0;
    final color = owes ? AppColors.amberDark : AppColors.success;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(AmazingIconOutlined.shoppingCart, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.stockType, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${sale.magunia} ${lang.t('magunia')} × ${AppFormatters.money(sale.pricePerBag)} • ${_time.format(sale.date)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 2,
                  children: [
                    Text(_typeLabel(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                    Text('${lang.t('paid')}: ${AppFormatters.money(sale.amountPaid)}', style: const TextStyle(fontSize: 12)),
                    if (owes)
                      Text('${lang.t('remaining')}: ${AppFormatters.money(sale.outstanding)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
                    if (sale.transactionId.isNotEmpty)
                      Text('${lang.t('transactionShort')}: ${sale.transactionId}', style: const TextStyle(fontSize: 12, color: AppColors.deepBlue)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(AppFormatters.money(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Payment payment;
  final LanguageProvider lang;

  const _PaymentRow({required this.payment, required this.lang});

  static final _time = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.success.withValues(alpha: 0.12),
            child: Icon(payment.isMobile ? AmazingIconOutlined.mobile : AmazingIconOutlined.tickCircle, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.t('debtPayment'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  [
                    payment.isMobile ? lang.t('mobile') : lang.t('cash'),
                    _time.format(payment.date),
                    if (payment.transactionId.isNotEmpty) '${lang.t('transactionShort')}: ${payment.transactionId}',
                    if (payment.note.isNotEmpty) payment.note,
                  ].join(' • '),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('− ${AppFormatters.money(payment.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success)),
        ],
      ),
    );
  }
}
