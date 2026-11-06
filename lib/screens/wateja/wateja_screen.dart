import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/debt_calculator.dart';
import '../../providers/customer_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/debt_badge.dart';
import '../../widgets/empty_state.dart';
import '../madeni/madeni_screen.dart';
import 'add_customer_sheet.dart';
import 'customer_detail_screen.dart';

class WatejaScreen extends StatefulWidget {
  /// A helper sees the list and can add customers, but not debts or details.
  final bool helperMode;
  final List<Widget> actions;

  const WatejaScreen({super.key, this.helperMode = false, this.actions = const []});

  @override
  State<WatejaScreen> createState() => _WatejaScreenState();
}

class _WatejaScreenState extends State<WatejaScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final salesProvider = context.watch<SalesProvider>();

    final debts = DebtCalculator.computeAll(customerProvider.customers, salesProvider.sales, customerProvider.payments);
    final filtered = debts.where((cd) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return cd.customer.name.toLowerCase().contains(q) || cd.customer.phone.contains(q);
    }).toList()
      ..sort((a, b) => a.customer.name.compareTo(b.customer.name));

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.t('watejaTitle')),
        actions: [
          if (!widget.helperMode)
            IconButton(
              icon: const Icon(AmazingIconOutlined.receipt),
              tooltip: lang.t('madeniTitle'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MadeniScreen())),
            ),
          ...widget.actions,
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'wateja_fab',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddCustomerSheet(),
        ),
        child: const Icon(AmazingIconOutlined.userAdd),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Responsive.sidePadding(context), 16, Responsive.sidePadding(context), 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: lang.t('search'),
                prefixIcon: const Icon(AmazingIconOutlined.searchNormal, size: 20),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(icon: AmazingIconOutlined.people, message: lang.t('noCustomers'))
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(Responsive.sidePadding(context), 8, Responsive.sidePadding(context), 90),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final cd = filtered[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.deepBlue.withValues(alpha: 0.1),
                            child: Text(
                              cd.customer.name.isNotEmpty ? cd.customer.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(cd.customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(cd.customer.phone, style: const TextStyle(fontSize: 12.5)),
                          trailing: widget.helperMode ? null : DebtBadge(balance: cd.balance, noDebtLabel: lang.t('noDebt')),
                          onTap: widget.helperMode
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: cd.customer)),
                                  ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
