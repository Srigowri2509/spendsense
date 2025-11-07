// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/wallets_sheet.dart';
import 'subscriptions_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(app.userInitials)),
            title: Text(app.userDisplayName),
            subtitle: Text(app.userDisplayEmail),
          ),

          const SizedBox(height: 8),

          // TODO: Wallets - Future feature
          // Card(
          //   child: ListTile(
          //     leading: const Icon(Icons.account_balance_wallet_outlined),
          //     title: const Text('Wallets'),
          //     subtitle: const Text('Deposit, withdraw to bank, set goals'),
          //     trailing: const Icon(Icons.chevron_right),
          //     onTap: () => showWalletsSheet(context),
          //   ),
          // ),
          // const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.subscriptions_outlined),
              title: const Text('Subscriptions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
