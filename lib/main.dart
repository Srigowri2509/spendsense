// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'theme.dart';
import 'app_state.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/spending_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/linked_banks_screen.dart';
import 'screens/puzzle_screen.dart';


void main() => runApp(const SpendSenseApp());

class SpendSenseApp extends StatelessWidget {
  const SpendSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: AppState()..seedDemoData(),
      child: Builder(
        builder: (context) {
          final app = AppScope.of(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SpendSense',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: app.themeMode,
            routes: {
              '/': (_) => const RootShell(),
              InsightsScreen.route: (_) => const InsightsScreen(),
              AddExpenseScreen.route: (_) => const AddExpenseScreen(),
              SpendingScreen.route: (_) => const SpendingScreen(),
              SettingsScreen.route: (_) => const SettingsScreen(),
              LinkedBanksScreen.route: (_) => const LinkedBanksScreen(),
              PuzzleScreen.route: (_) => const PuzzleScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Bottom nav: Home / Insights / Add / Spending / Settings
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
    SettingsScreen(),
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
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
