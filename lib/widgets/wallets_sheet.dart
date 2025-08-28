// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../app_state.dart';

class WalletItem {
  final String id;
  final String name;
  final String amount;
  final IconData icon;
  const WalletItem(this.id, this.name, this.amount, this.icon);
}

/// Call this from anywhere: `showWalletsSheet(context);`
void showWalletsSheet(BuildContext context) {
  final app = AppScope.of(context);
  final items = app.wallets
      .map((w) => WalletItem(w.id, w.name, formatCurrency(w.balance, symbol: app.currencySymbol), w.icon))
      .toList();

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _WalletsSheet(items: items),
  );
}

class _WalletsSheet extends StatelessWidget {
  final List<WalletItem> items;
  const _WalletsSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),
          Row(
            children: [
              Text('Wallets', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _WalletTile(item: items[i]),
          ),
        ],
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  final WalletItem item;
  const _WalletTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () async {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => SafeArea(
            child: Wrap(children: [
              ListTile(title: const Text('Deposit'), onTap: () => Navigator.pop(context, 'deposit')),
              ListTile(title: const Text('Withdraw to bank'), onTap: () => Navigator.pop(context, 'withdraw')),
              ListTile(title: const Text('Set goal (target)'), onTap: () => Navigator.pop(context, 'goal')),
            ]),
          ),
        );
        if (action == null) return;
        if (action == 'deposit') {
          final v = await _askAmountSheet(context, 'Deposit amount');
          if (v != null && v > 0) app.depositToWallet(item.id, v);
        } else if (action == 'withdraw') {
          final res = await _askWithdrawSheet(context);
          if (res != null) {
            final (amount, _bankId) = res;
            app.withdrawFromWallet(item.id, amount);
          }
        } else if (action == 'goal') {
          final v = await _askAmountSheet(context, 'Wallet goal (target)');
          if (v != null && v >= 0) app.setWalletTarget(item.id, v);
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated')));
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(item.icon), const Spacer(), const Icon(Icons.more_horiz, size: 18)]),
            const Spacer(),
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(item.amount, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

// Unique dialog helpers for this sheet
Future<double?> _askAmountSheet(BuildContext context, String title) async {
  final ctrl = TextEditingController();
  return showDialog<double>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(prefixText: '₹ ', hintText: '0'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text.trim())), child: const Text('OK')),
      ],
    ),
  );
}

Future<(double, String)?> _askWithdrawSheet(BuildContext context) async {
  final app = AppScope.of(context);
  double? amount;
  String? bankId = app.banks.isNotEmpty ? app.banks.first.id : null;

  return showDialog<(double, String)>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Withdraw to bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '₹ ', hintText: 'Amount'),
              onChanged: (t) => amount = double.tryParse(t.trim()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: bankId,
              items: app.banks.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.name} (${b.type})'))).toList(),
              onChanged: (v) => setState(() => bankId = v),
              decoration: const InputDecoration(labelText: 'Bank account'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (amount != null && bankId != null) Navigator.pop(context, (amount!, bankId!));
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    ),
  );
}
