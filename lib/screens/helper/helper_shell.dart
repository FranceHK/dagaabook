import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amazing_icons/outlined.dart';
import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/empty_state.dart';
import '../mizigo/sell_stock_screen.dart';
import '../wateja/wateja_screen.dart';

/// The whole app as a helper sees it: sell for cash and see/add customers.
/// Nothing else (stock buying, debts, reports, editing) is reachable.
class HelperShell extends StatefulWidget {
  const HelperShell({super.key});

  @override
  State<HelperShell> createState() => _HelperShellState();
}

class _HelperShellState extends State<HelperShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    const actions = [_SyncButton(), _LogoutButton()];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _SellTab(actions: actions),
          WatejaScreen(helperMode: true, actions: actions),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(AmazingIconOutlined.shoppingCart), label: lang.t('sellTab')),
          NavigationDestination(icon: const Icon(AmazingIconOutlined.people), label: lang.t('watejaTitle')),
        ],
      ),
    );
  }
}

class _SellTab extends StatelessWidget {
  final List<Widget> actions;

  const _SellTab({required this.actions});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final auth = context.watch<AuthProvider>();
    final sync = context.watch<SyncProvider>();
    final stock = context.watch<InventoryProvider>().items.where((s) => !s.isSoldOut).toList();
    final mySales = context.watch<SalesProvider>().today.where((s) => s.soldBy == auth.helperId).toList();
    final myTotal = mySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final myBoxes = mySales.fold(0, (sum, s) => sum + s.magunia);
    final pad = Responsive.sidePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(auth.helperName.isEmpty ? lang.t('appName') : auth.helperName), actions: actions),
      body: ListView(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
        children: [
          if (sync.error == 'unauthorized')
            Card(
              color: AppColors.danger.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(lang.t('helperSignedOut'), style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.heroGradient),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.t('mySalesToday'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(AppFormatters.money(myTotal), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$myBoxes ${lang.t('magunia')} · ${mySales.length} ${lang.t('sellTab').toLowerCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(lang.t('inStore'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          if (stock.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: EmptyState(icon: AmazingIconOutlined.box, message: lang.t('noStockToSell')),
            ),
          for (final item in stock)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: AppColors.amber.withValues(alpha: 0.15),
                  child: const Icon(AmazingIconOutlined.box, color: AppColors.amberDark, size: 20),
                ),
                title: Text(item.type, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${item.remainingMagunia} ${lang.t('magunia')} · ${AppFormatters.money(item.sellingPricePerBag)}'),
                trailing: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SellStockScreen(stockItem: item, helperId: auth.helperId)),
                  ),
                  child: Text(lang.t('sell')),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final sync = context.watch<SyncProvider>();
    final color = sync.error != null
        ? AppColors.danger
        : sync.hasPending
            ? AppColors.warning
            : null;

    return IconButton(
      tooltip: sync.hasPending ? lang.t('syncPending') : lang.t('syncNow'),
      onPressed: sync.isBusy ? null : () => sync.syncNow(),
      icon: sync.isBusy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(sync.hasPending || sync.error != null ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined, color: color),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  Future<void> _logout(BuildContext context) async {
    final lang = context.read<LanguageProvider>();
    final auth = context.read<AuthProvider>();
    final sync = context.read<SyncProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Sales still on this phone would be lost, so send them first.
    var question = lang.t('logoutConfirm');
    if (sync.hasPending && !await sync.syncNow()) {
      if (sync.error != 'unauthorized') {
        messenger.showSnackBar(SnackBar(content: Text(lang.t('unsentSales'))));
        return;
      }
      question = lang.t('logoutAnyway');
    }
    if (!context.mounted) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(question),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(lang.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(lang.t('logout'))),
        ],
      ),
    );
    if (leave != true) return;

    await sync.reset();
    await auth.logout();
    await Future.wait(sync.reloaders.map((reload) => reload()));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return IconButton(
      tooltip: lang.t('logout'),
      icon: const Icon(AmazingIconOutlined.logout),
      onPressed: () => _logout(context),
    );
  }
}
