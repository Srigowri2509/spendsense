import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/parsed_transaction.dart';
import '../utils/category_matcher.dart';

class TransactionPreviewTile extends StatelessWidget {
  final ParsedTransaction transaction;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const TransactionPreviewTile({
    super.key,
    required this.transaction,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final suggestedCategory = CategoryMatcher.matchCategory(transaction.merchant);
    final category = app.categories.firstWhere(
      (c) => c.type == suggestedCategory,
      orElse: () => app.categories.first,
    );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: onChanged,
        secondary: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.2),
          child: Icon(category.icon, color: category.color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.merchant,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              formatCurrency(transaction.amount, symbol: app.currencySymbol),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} • ${transaction.paymentMethod}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(category.icon, size: 14, color: category.color),
                const SizedBox(width: 4),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: category.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
