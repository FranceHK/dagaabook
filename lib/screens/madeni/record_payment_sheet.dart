import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/language_provider.dart';

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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: lang.t('optional')),
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
        );
    if (mounted) {
      Navigator.of(context).pop();
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t('paymentRecorded'))));
    }
  }
}
