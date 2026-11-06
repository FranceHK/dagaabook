import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/transaction_ids.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';

class RecordPaymentSheet extends StatefulWidget {
  final Customer customer;
  final double currentBalance;

  const RecordPaymentSheet({super.key, required this.customer, required this.currentBalance});

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _transactionController = TextEditingController();
  bool _isMobile = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(lang.t('recordPaymentTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.customer.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text('${lang.t('currentDebt')}: ${AppFormatters.money(widget.currentBalance)}',
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(labelText: lang.t('paymentAmount'), prefixText: 'TSh '),
                validator: (v) {
                  final parsed = double.tryParse(v ?? '');
                  if (parsed == null || parsed <= 0) return lang.t('required');
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(lang.t('paymentMethod'), style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(label: Text(lang.t('cash')), selected: !_isMobile, onSelected: (_) => setState(() => _isMobile = false)),
                  ChoiceChip(label: Text(lang.t('mobile')), selected: _isMobile, onSelected: (_) => setState(() => _isMobile = true)),
                ],
              ),
              if (_isMobile) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _transactionController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: lang.t('transactionId'), hintText: lang.t('transactionIdHint')),
                  validator: (v) {
                    final id = (v ?? '').trim();
                    if (id.isEmpty) return lang.t('transactionIdRequired');
                    final sales = context.read<SalesProvider>().sales;
                    final payments = context.read<CustomerProvider>().payments;
                    if (TransactionIds.isUsed(id, sales, payments)) return lang.t('transactionIdUsed');
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: '${lang.t('note')} (${lang.t('optional')})'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text(lang.t('save'))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<CustomerProvider>().recordPayment(
          customerId: widget.customer.id,
          amount: double.parse(_amountController.text),
          note: _noteController.text.trim(),
          method: _isMobile ? 'mobile' : 'cash',
          transactionId: _isMobile ? TransactionIds.normalize(_transactionController.text) : '',
        );
    if (mounted) {
      Navigator.of(context).pop();
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t('paymentRecorded'))));
    }
  }
}
