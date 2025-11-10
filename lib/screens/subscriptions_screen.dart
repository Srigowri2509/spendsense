import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/empty_state.dart';

class SubscriptionsScreen extends StatefulWidget {
  static const route = '/subscriptions';
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).markBingoEvent('subscriptions_viewed');
    });
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final billingDayController = TextEditingController();
    final daysUntilController = TextEditingController();
    bool isFixed = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Name',
                    hintText: 'e.g., Netflix, Spotify',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: billingDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Billing Day (1-31)',
                    hintText: 'Day of month when billed',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: daysUntilController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Days Until Next Billing',
                    hintText: 'How many days until next payment?',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Count as fixed expense'),
                  value: isFixed,
                  onChanged: (value) => setState(() => isFixed = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                final billingDay = int.tryParse(billingDayController.text.trim());
                final daysUntil = int.tryParse(daysUntilController.text.trim());

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a subscription name')),
                  );
                  return;
                }

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                if (billingDay == null || billingDay < 1 || billingDay > 31) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid billing day (1-31)')),
                  );
                  return;
                }

                if (daysUntil == null || daysUntil < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid days until next billing')),
                  );
                  return;
                }

                final app = AppScope.of(context);
                app.addSubscription(
                  name: name,
                  amount: amount,
                  billingDay: billingDay,
                  daysUntilNextBilling: daysUntil,
                  isFixed: isFixed,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added subscription: $name')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final total = state.subscriptions.fold<double>(0, (a, s) => a + s.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: state.subscriptions.isEmpty
          ? EmptyState(
              icon: Icons.subscriptions_outlined,
              title: 'No subscriptions',
              message: 'Track your recurring payments by adding subscriptions',
              actionLabel: 'Add Subscription',
              onAction: () => _showAddSubscriptionDialog(context),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...state.subscriptions.map((s) {
                  final daysRemaining = s.daysRemaining;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.subscriptions_outlined),
                      title: Text(s.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Billing day: ${s.billingDay}'),
                          const SizedBox(height: 4),
                          Text(
                            daysRemaining == 0
                                ? 'Due today!'
                                : daysRemaining == 1
                                    ? 'Due tomorrow'
                                    : '$daysRemaining days until next billing',
                            style: TextStyle(
                              color: daysRemaining <= 3
                                  ? Colors.red
                                  : daysRemaining <= 7
                                      ? Colors.orange
                                      : null,
                              fontWeight: daysRemaining <= 7 ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(s.amount),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (s.isFixed)
                            Text(
                              'Fixed',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: Text(
                      'Total Monthly',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    trailing: Text(
                      formatCurrency(total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
