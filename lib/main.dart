// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'theme.dart'; // <-- uses AppTheme.light() / AppTheme.dark()

// SCREENS
import 'screens/auth_gate.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/spending_screen.dart';
import 'screens/settings_screen.dart';

void main() => runApp(const SpendSenseApp());

class SpendSenseApp extends StatefulWidget {
  const SpendSenseApp({super.key});
  @override
  State<SpendSenseApp> createState() => _SpendSenseAppState();
}

class _SpendSenseAppState extends State<SpendSenseApp> {
  late final AppState app = AppState();

  @override
  void initState() {
    super.initState();
    app.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: app,
      child: Builder(
        builder: (context) {
          final app = AppScope.of(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SpendSense',
            // use your palette-based themes
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: app.themeMode,
            home: const AuthGate(), // decides between auth screen and the app shell
          );
        },
      ),
    );
  }
}

/// Bottom nav shell
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  late final List<Widget> _pages = const [
    HomeScreen(),
    InsightsScreen(),
    AddExpenseScreen(),
    SpendingScreen(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Add'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Spending'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
