import 'package:flutter/material.dart';
import '../app_state.dart';

class ActivityTile extends StatelessWidget {
  final TransactionItem item;
  const ActivityTile({super.key, required this.item});

  IconData get icon {
    switch (item.category) {
      case CategoryType.food:
        return Icons.restaurant_outlined;
      case CategoryType.travel:
        return Icons.directions_car_outlined;
      case CategoryType.shopping:
        return Icons.shopping_bag_outlined;
      case CategoryType.rent:
        return Icons.home_work_outlined;
      case CategoryType.luxuries:
        return Icons.stars_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(item.time).format(context);
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(item.merchant),
      subtitle: Text('${item.source} • $time'),
      trailing: Text(
        '- ${formatCurrency(item.amount)}',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
