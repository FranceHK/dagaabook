import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/responsive.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/stock_item.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/summary_card.dart';
import '../main_shell.dart';
import 'add_stock_sheet.dart';
import 'sell_stock_screen.dart';

class MizigoScreen extends StatelessWidget {
  const MizigoScreen({super.key});

  void _openAddStock(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddStockSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final inventory = context.watch<InventoryProvider>();
    final items = inventory.items;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AmazingIconOutlined.arrowLeft),
          onPressed: () {
            final controller = MainShellController.maybeOf(context);
            if (controller != null) {
              controller.goToTab(0);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(lang.t('mizigoTitle')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'mizigo_fab',
        onPressed: () => _openAddStock(context),
        child: const Icon(AmazingIconOutlined.add),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Responsive.sidePadding(context), 16, Responsive.sidePadding(context), 90),
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: lang.t('remainingBags'),
                  value: '${inventory.totalMaguniaRemaining} ${lang.t('magunia')}',
                  subtitle: '${inventory.totalMaguniaIn} ${lang.t('totalBags').toLowerCase()}',
                  icon: AmazingIconOutlined.bag,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  label: lang.t('totalStockValue'),
                  value: AppFormatters.money(inventory.totalStockValue),
                  icon: AmazingIconOutlined.wallet,
                  accentColor: AppColors.amberDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            EmptyState(icon: AmazingIconOutlined.bag, message: lang.t('noStock'))
          else
            for (final item in items) _StockCard(item: item, lang: lang),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockItem item;
  final LanguageProvider lang;

  const _StockCard({required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    final soldOut = item.isSoldOut;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.type, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (soldOut ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      soldOut ? lang.t('soldOut') : lang.t('inStock'),
                      style: TextStyle(color: soldOut ? AppColors.danger : AppColors.success, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StockStat(label: lang.t('remainingBags'), value: '${item.remainingMagunia} / ${item.totalMagunia}'),
                  _StockStat(label: lang.t('purchasePricePerBag'), value: AppFormatters.money(item.purchasePricePerBag)),
                  _StockStat(label: lang.t('sellingPricePerBag'), value: AppFormatters.money(item.sellingPricePerBag)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.supplier.isNotEmpty)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AmazingIconOutlined.truck, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(child: Text(item.supplier, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Text(AppFormatters.date(item.dateAdded), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: soldOut
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SellStockScreen(stockItem: item)),
                          ),
                  icon: const Icon(AmazingIconOutlined.shop, size: 18),
                  label: Text(lang.t('sell')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockStat extends StatelessWidget {
  final String label;
  final String value;

  const _StockStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
