import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/debt_calculator.dart';
import '../../core/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/summary_card.dart';
import '../wateja/customer_detail_screen.dart';
import 'record_payment_sheet.dart';

enum _SortMode { amount, date }

class MadeniScreen extends StatefulWidget {
  const MadeniScreen({super.key});

  @override
  State<MadeniScreen> createState() => _MadeniScreenState();
}

class _MadeniScreenState extends State<MadeniScreen> {
  _SortMode _sortMode = _SortMode.amount;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final salesProvider = context.watch<SalesProvider>();

    final debts = DebtCalculator.computeAll(customerProvider.customers, salesProvider.sales, customerProvider.payments)
        .where((cd) => cd.hasDebt)
        .toList();

    if (_sortMode == _SortMode.amount) {
      debts.sort((a, b) => b.balance.compareTo(a.balance));
    } else {
      debts.sort((a, b) {
        final da = a.lastActivity ?? DateTime(2000);
        final db = b.lastActivity ?? DateTime(2000);
        return da.compareTo(db);
      });
    }

    final totalOwed = debts.fold(0.0, (sum, cd) => sum + cd.balance);

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('madeniTitle'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Responsive.sidePadding(context), 16, Responsive.sidePadding(context), 24),
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: lang.t('totalOwed'),
                  value: AppFormatters.money(totalOwed),
                  subtitle: '${debts.length} ${lang.t('debtors')}',
                  icon: AmazingIconOutlined.receipt,
                  accentColor: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ChoiceChip(
                label: Text(lang.t('sortByAmount')),
                selected: _sortMode == _SortMode.amount,
                onSelected: (_) => setState(() => _sortMode = _SortMode.amount),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(lang.t('sortByDate')),
                selected: _sortMode == _SortMode.date,
                onSelected: (_) => setState(() => _sortMode = _SortMode.date),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (debts.isEmpty)
            EmptyState(icon: AmazingIconOutlined.tickCircle, message: lang.t('noDebts'))
          else
            for (final cd in debts) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: cd.customer)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                              child: Text(
                                cd.customer.name.isNotEmpty ? cd.customer.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cd.customer.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                    cd.lastActivity != null
                                        ? '${lang.t('dueDate')}: ${AppFormatters.dateShort(cd.lastActivity!)}'
                                        : cd.customer.phone,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(AppFormatters.money(cd.balance), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => RecordPaymentSheet(customer: cd.customer, currentBalance: cd.balance),
                          ),
                          icon: const Icon(AmazingIconOutlined.wallet, size: 16),
                          label: Text(lang.t('recordPayment')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
