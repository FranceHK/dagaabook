import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/language_provider.dart';

class AddStockSheet extends StatefulWidget {
  const AddStockSheet({super.key});

  @override
  State<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends State<AddStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _maguniaController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _supplierController = TextEditingController();

  @override
  void dispose() {
    _typeController.dispose();
    _maguniaController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _supplierController.dispose();
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
          child: SingleChildScrollView(
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
                Text(lang.t('addStockTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _typeController,
                  decoration: InputDecoration(labelText: lang.t('stockType')),
                  validator: (v) => (v == null || v.trim().isEmpty) ? lang.t('required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maguniaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: lang.t('totalMaguniaIn'), suffixText: lang.t('magunia')),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return lang.t('required');
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: lang.t('purchasePricePerBag'), prefixText: 'TSh '),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? lang.t('required') : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: lang.t('sellingPricePerBag'), prefixText: 'TSh '),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? lang.t('required') : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supplierController,
                  decoration: InputDecoration(labelText: '${lang.t('supplier')} (${lang.t('optional')})'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(lang.t('save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<InventoryProvider>().addStock(
          type: _typeController.text.trim(),
          totalMagunia: int.parse(_maguniaController.text),
          purchasePricePerBag: double.parse(_purchasePriceController.text),
          sellingPricePerBag: double.parse(_sellingPriceController.text),
          supplier: _supplierController.text.trim(),
        );
    if (mounted) {
      Navigator.of(context).pop();
      final lang = context.read<LanguageProvider>();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t('stockAdded'))));
    }
  }
}
