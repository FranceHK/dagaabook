import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';

/// Adds a new customer, or edits [customer] when one is given.
class AddCustomerSheet extends StatefulWidget {
  final Customer? customer;

  const AddCustomerSheet({super.key, this.customer});

  @override
  State<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.customer?.name);
  late final _phoneController = TextEditingController(text: widget.customer?.phone);
  late final _locationController = TextEditingController(text: widget.customer?.location);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
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
              Text(lang.t(widget.customer == null ? 'addCustomerTitle' : 'editCustomerTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: lang.t('customerName')),
                validator: (v) => (v == null || v.trim().isEmpty) ? lang.t('required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: lang.t('phoneNumber')),
                validator: (v) => (v == null || v.trim().isEmpty) ? lang.t('required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: '${lang.t('location')} (${lang.t('optional')})'),
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
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final location = _locationController.text.trim();
    final existing = widget.customer;
    if (existing == null) {
      await context.read<CustomerProvider>().addCustomer(name: name, phone: phone, location: location);
    } else {
      final sales = context.read<SalesProvider>();
      await context.read<CustomerProvider>().updateCustomer(existing.id, name: name, phone: phone, location: location);
      await sales.renameCustomer(existing.id, name);
    }
    if (mounted) Navigator.of(context).pop();
  }
}
