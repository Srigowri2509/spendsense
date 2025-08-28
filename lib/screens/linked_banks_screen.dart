import 'package:flutter/material.dart';
import '../app_state.dart';

class LinkedBanksScreen extends StatelessWidget {
  static const route = '/banks';
  const LinkedBanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Linked Banks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...state.banks.map((b) => Card(
                child: SwitchListTile(
                  value: b.linked,
                  onChanged: (_) => state.toggleBank(b.id),
                  title: Text(b.name),
                  subtitle: Text('${b.type} • Read-only access'),
                ),
              )),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Bank Account'),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          ListTile(
            title: const Text('Privacy'),
            subtitle: const Text('Read-only access & local processing'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
