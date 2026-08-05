import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/customer.dart';
import '../../models/sale.dart';
import '../../models/stock_item.dart';
import '../../providers/customer_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/api_service.dart';

/// Full-page "Uza" flow: search/pick a customer (or add one inline), choose
/// how many magunia they're taking from this specific stock batch, and
/// settle payment as cash, mobile money, full credit, or a partial payment
/// (the remainder becomes debt, visible under Madeni/Wateja).
class SellStockScreen extends StatefulWidget {
  final StockItem stockItem;

  const SellStockScreen({super.key, required this.stockItem});

  @override
  State<SellStockScreen> createState() => _SellStockScreenState();
}

class _SellStockScreenState extends State<SellStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maguniaController = TextEditingController();
  final _partialAmountController = TextEditingController();
  late TextEditingController _customerNameController;

  Customer? _selectedCustomer;
  PaymentType _paymentType = PaymentType.cash;

  int get _magunia => int.tryParse(_maguniaController.text) ?? 0;

  double get _total => _magunia * widget.stockItem.sellingPricePerBag;

  @override
  void dispose() {
    _maguniaController.dispose();
    _partialAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final customers = context.watch<CustomerProvider>().customers;
    final remaining = widget.stockItem.remainingMagunia;

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('sellStockTitle'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.deepBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.deepBlue.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.stockItem.type, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoStat(label: lang.t('availableToSell'), value: '$remaining ${lang.t('magunia')}'),
                      ),
                      Expanded(
                        child: _InfoStat(label: lang.t('sellingPricePerBag'), value: AppFormatters.money(widget.stockItem.sellingPricePerBag)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Autocomplete<Customer>(
              displayStringForOption: (c) => c.name,
              optionsBuilder: (value) {
                if (value.text.trim().isEmpty) return const Iterable<Customer>.empty();
                final q = value.text.toLowerCase();
                return customers.where((c) => c.name.toLowerCase().contains(q));
              },
              onSelected: (c) => setState(() => _selectedCustomer = c),
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                _customerNameController = controller;
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: lang.t('selectCustomer'),
                    hintText: lang.t('searchCustomerHint'),
                    prefixIcon: const Icon(AmazingIconOutlined.searchNormal, size: 20),
                  ),
                  onChanged: (_) {
                    if (_selectedCustomer != null) setState(() => _selectedCustomer = null);
                  },
                  validator: (v) => (v == null || v.trim().isEmpty) ? lang.t('required') : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 40,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, i) {
                            final c = options.elementAt(i);
                            return ListTile(
                              dense: true,
                              leading: const Icon(AmazingIconOutlined.user, size: 20),
                              title: Text(c.name, style: const TextStyle(fontSize: 14)),
                              subtitle: Text(c.phone, style: const TextStyle(fontSize: 12)),
                              onTap: () => onSelected(c),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_selectedCustomer == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(lang.t('newCustomerNote'), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maguniaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: lang.t('quantityBags'), suffixText: lang.t('magunia')),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return lang.t('required');
                if (n > remaining) return lang.t('insufficientStock');
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang.t('totalAmount'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(AppFormatters.money(_total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.amberDark)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(lang.t('paymentType'), style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: [
                _PaymentOption(
                  label: lang.t('cash'),
                  icon: AmazingIconOutlined.wallet,
                  selected: _paymentType == PaymentType.cash,
                  onTap: () => setState(() => _paymentType = PaymentType.cash),
                ),
                _PaymentOption(
                  label: lang.t('mobile'),
                  icon: AmazingIconOutlined.mobile,
                  selected: _paymentType == PaymentType.mobile,
                  onTap: () => setState(() => _paymentType = PaymentType.mobile),
                ),
                _PaymentOption(
                  label: lang.t('credit'),
                  icon: AmazingIconOutlined.clock,
                  selected: _paymentType == PaymentType.credit,
                  onTap: () => setState(() => _paymentType = PaymentType.credit),
                ),
                _PaymentOption(
                  label: lang.t('partial'),
                  icon: AmazingIconOutlined.percentageCircle,
                  selected: _paymentType == PaymentType.partial,
                  onTap: () => setState(() => _paymentType = PaymentType.partial),
                ),
              ],
            ),
            if (_paymentType == PaymentType.partial) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _partialAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: lang.t('amountPaidNow'), prefixText: 'TSh '),
                validator: (v) {
                  if (_paymentType != PaymentType.partial) return null;
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return lang.t('required');
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(lang.t('sell')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = context.read<LanguageProvider>();
    final inventory = context.read<InventoryProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final salesProvider = context.read<SalesProvider>();

    final magunia = _magunia;
    if (magunia > widget.stockItem.remainingMagunia) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t('insufficientStock'))));
      return;
    }

    Customer? customer = _selectedCustomer;
    final typedName = _customerNameController.text.trim();
    if (customer == null) {
      try {
        customer = customerProvider.customers.firstWhere((c) => c.name.toLowerCase() == typedName.toLowerCase());
      } catch (_) {
        customer = await customerProvider.addCustomer(name: typedName, phone: '');
      }
    }

    final total = _total;
    final amountPaid = switch (_paymentType) {
      PaymentType.cash || PaymentType.mobile => total,
      PaymentType.credit => 0.0,
      PaymentType.partial => double.tryParse(_partialAmountController.text) ?? 0,
    };

    if (!ApiService.isAvailable) {
      inventory.recordSale(stockItemId: widget.stockItem.id, magunia: magunia);
    }

    await salesProvider.addSale(
      stockItemId: widget.stockItem.id,
      stockType: widget.stockItem.type,
      customerId: customer.id,
      customerName: customer.name,
      magunia: magunia,
      pricePerBag: widget.stockItem.sellingPricePerBag,
      paymentType: _paymentType,
      amountPaid: amountPaid,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t('saleRecorded'))));
    }
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.deepBlue.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.deepBlue : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.deepBlue : AppColors.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.deepBlue : AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
