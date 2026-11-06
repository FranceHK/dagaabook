import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/sale.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/summary_card.dart';

/// Read-only ledger of past sales. New sales are always started from a
/// specific stock batch via the "Uza" button on Mizigo, so this screen has
/// no add action — that keeps every sale properly linked to inventory.
class MauzoScreen extends StatefulWidget {
  const MauzoScreen({super.key});

  @override
  State<MauzoScreen> createState() => _MauzoScreenState();
}

class _MauzoScreenState extends State<MauzoScreen> {
  bool _todayOnly = false;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final salesProvider = context.watch<SalesProvider>();
    final sales = _todayOnly ? salesProvider.today : salesProvider.sales;

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('mauzoTitle'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Responsive.sidePadding(context), 16, Responsive.sidePadding(context), 24),
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: lang.t('todaysSales'),
                  value: AppFormatters.money(salesProvider.totalRevenueToday),
                  subtitle: '${salesProvider.today.length} ${lang.t('entries')}',
                  icon: AmazingIconOutlined.calendar,
                  accentColor: AppColors.amberDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: lang.t('allSales'),
                  value: '${salesProvider.sales.length}',
                  icon: AmazingIconOutlined.receipt,
                  accentColor: AppColors.deepBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(label: Text(lang.t('allSales')), selected: !_todayOnly, onSelected: (_) => setState(() => _todayOnly = false)),
              const SizedBox(width: 8),
              ChoiceChip(label: Text(lang.t('today')), selected: _todayOnly, onSelected: (_) => setState(() => _todayOnly = true)),
            ],
          ),
          const SizedBox(height: 16),
          if (sales.isEmpty)
            EmptyState(icon: AmazingIconOutlined.money, message: lang.t('noSales'))
          else
            for (final sale in sales) _SaleCard(sale: sale, lang: lang),
        ],
      ),
    );
  }
}

extension on PaymentType {
  IconData get icon => switch (this) {
        PaymentType.cash => AmazingIconOutlined.wallet,
        PaymentType.mobile => AmazingIconOutlined.mobile,
        PaymentType.credit => AmazingIconOutlined.clock,
        PaymentType.partial => AmazingIconOutlined.percentageCircle,
      };

  Color get color => switch (this) {
        PaymentType.cash || PaymentType.mobile => AppColors.success,
        PaymentType.credit || PaymentType.partial => AppColors.amberDark,
      };

  String label(LanguageProvider lang) => switch (this) {
        PaymentType.cash => lang.t('cash'),
        PaymentType.mobile => lang.t('mobile'),
        PaymentType.credit => lang.t('credit'),
        PaymentType.partial => lang.t('partial'),
      };
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final LanguageProvider lang;

  const _SaleCard({required this.sale, required this.lang});

  @override
  Widget build(BuildContext context) {
    final type = sale.paymentType;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: type.color.withValues(alpha: 0.15),
            child: Icon(type.icon, color: type.color),
          ),
          title: Text(sale.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          subtitle: Text(
            '${sale.magunia} ${lang.t('magunia')} @ ${AppFormatters.money(sale.pricePerBag)} • ${AppFormatters.dateShort(sale.date)}'
            '${sale.transactionId.isNotEmpty ? '\n${lang.t('transactionShort')}: ${sale.transactionId}' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppFormatters.money(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                type.label(lang),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: type.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
