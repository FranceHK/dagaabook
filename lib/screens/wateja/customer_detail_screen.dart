import 'package:flutter/material.dart';
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
import '../../widgets/debt_badge.dart';
import '../../widgets/empty_state.dart';
import '../madeni/record_payment_sheet.dart';
import 'add_customer_sheet.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final salesProvider = context.watch<SalesProvider>();
    // Read the latest copy so edits show straight away.
    final customer = customerProvider.byId(widget.customer.id) ?? widget.customer;

    final sales = salesProvider.salesForCustomer(widget.customer.id);
    final payments = customerProvider.paymentsForCustomer(widget.customer.id);
    final balance = DebtCalculator.balanceFor(widget.customer.id, salesProvider.sales, customerProvider.payments);
    final totalPurchased = sales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final totalPaid = sales.fold(0.0, (sum, s) => sum + s.amountPaid) + payments.fold(0.0, (sum, p) => sum + p.amount);

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
      body: Column(
        children: [
          Container(
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
                const SizedBox(height: 4),
                Text(customer.phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                if (customer.location.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(customer.location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${lang.t('call')}: ${customer.phone}')));
                      },
                      icon: const Icon(AmazingIconOutlined.call, size: 16),
                      label: Text(lang.t('call')),
                    ),
                    const SizedBox(width: 12),
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
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Responsive.sidePadding(context), vertical: 14),
            color: AppColors.surface,
            child: Row(
              children: [
                _StatColumn(label: lang.t('totalPurchased'), value: AppFormatters.money(totalPurchased)),
                _StatColumn(label: lang.t('totalPaid'), value: AppFormatters.money(totalPaid)),
                Expanded(
                  child: Column(
                    children: [
                      Text(lang.t('balance'), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      DebtBadge(balance: balance, noDebtLabel: lang.t('noDebt')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.deepBlue,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.amber,
            tabs: [
              Tab(text: lang.t('purchaseHistory')),
              Tab(text: lang.t('paymentHistory')),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PurchaseHistoryList(sales: sales, lang: lang),
                _PaymentHistoryList(payments: payments, lang: lang),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PurchaseHistoryList extends StatelessWidget {
  final List<Sale> sales;
  final LanguageProvider lang;

  const _PurchaseHistoryList({required this.sales, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return EmptyState(icon: AmazingIconOutlined.receipt, message: lang.t('noHistory'));
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: Responsive.sidePadding(context), vertical: 16),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final sale = sales[i];
        final createsDebt = sale.paymentType == PaymentType.credit || sale.paymentType == PaymentType.partial;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (createsDebt ? AppColors.amber : AppColors.success).withValues(alpha: 0.15),
              child: Icon(createsDebt ? AmazingIconOutlined.clock : AmazingIconOutlined.money, color: createsDebt ? AppColors.amberDark : AppColors.success),
            ),
            title: Text('${sale.stockType} • ${sale.magunia} ${lang.t('magunia')} @ ${AppFormatters.money(sale.pricePerBag)}'),
            subtitle: Text(
              AppFormatters.date(sale.date) +
                  (sale.transactionId.isNotEmpty ? '\n${lang.t('transactionShort')}: ${sale.transactionId}' : ''),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppFormatters.money(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                if (sale.outstanding > 0)
                  Text('${lang.t('balance')}: ${AppFormatters.money(sale.outstanding)}', style: const TextStyle(color: AppColors.danger, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentHistoryList extends StatelessWidget {
  final List<Payment> payments;
  final LanguageProvider lang;

  const _PaymentHistoryList({required this.payments, required this.lang});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) return EmptyState(icon: AmazingIconOutlined.wallet, message: lang.t('noHistory'));
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: Responsive.sidePadding(context), vertical: 16),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final payment = payments[i];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0x1F2ECC71),
              child: Icon(AmazingIconOutlined.tickCircle, color: AppColors.success),
            ),
            title: Text(AppFormatters.money(payment.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text([
              payment.isMobile ? lang.t('mobile') : lang.t('cash'),
              if (payment.transactionId.isNotEmpty) '${lang.t('transactionShort')}: ${payment.transactionId}',
              if (payment.note.isNotEmpty) payment.note,
            ].join(' • ')),
            trailing: Text(AppFormatters.dateShort(payment.date), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        );
      },
    );
  }
}
