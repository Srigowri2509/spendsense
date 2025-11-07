import 'package:flutter/material.dart';
import '../app_state.dart';

class ActivityTile extends StatelessWidget {
  final TransactionItem item;
  const ActivityTile({super.key, required this.item});

  IconData _getCategoryIcon(BuildContext context) {
    final app = AppScope.of(context);
    try {
      final category = app.categories.firstWhere((c) => c.type == item.category);
      return category.icon;
    } catch (_) {
      // Fallback if category not found
      return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(item.time).format(context);
    return ListTile(
      leading: CircleAvatar(child: Icon(_getCategoryIcon(context))),
      title: Text(item.merchant),
      subtitle: Text('${item.source} • $time'),
      trailing: Text(
        '- ${formatCurrency(item.amount)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
