// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'theme.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/linked_banks_screen.dart';
import 'screens/spending_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/subscriptions_screen.dart';

void main() => runApp(const SpendSenseApp());

class SpendSenseApp extends StatelessWidget {
  const SpendSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: AppState()..seedDemoData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SpendSense',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routes: {
          '/': (context) => const RootShell(),
          LinkedBanksScreen.route: (_) => const LinkedBanksScreen(),
          SpendingScreen.route: (_) => const SpendingScreen(),
          AddExpenseScreen.route: (_) => const AddExpenseScreen(),
          InsightsScreen.route: (_) => const InsightsScreen(),
          SubscriptionsScreen.route: (_) => const SubscriptionsScreen(),
        },
      ),
    );
  }
}

/// Bottom navigation shell
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    InsightsScreen(),
    AddExpenseScreen(),
    SpendingScreen(),
    LinkedBanksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Spending'),
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance), label: 'Banks'),
        ],
      ),
    );
  }
}
