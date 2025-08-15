import 'package:flutter/material.dart';
import '../app_state.dart';

class SubscriptionsScreen extends StatelessWidget {
  static const route = '/subscriptions';
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final total = state.subscriptions.fold<double>(0, (a, s) => a + s.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: ListView(
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
