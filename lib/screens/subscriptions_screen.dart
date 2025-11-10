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
              onAction: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add subscription feature coming soon')),
                );
              },
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...state.subscriptions.map((s) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.subscriptions_outlined),
                        title: Text(s.name),
                        subtitle: Text('Billing day: ${s.billingDay}'),
                        trailing: Text(formatCurrency(s.amount)),
                      ),
                    )),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Total'),
                  trailing: Text(formatCurrency(total)),
                ),
              ],
            ),
    );
  }
}
