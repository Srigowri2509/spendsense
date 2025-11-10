// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../main.dart';
import 'budget_setup_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.isSignedIn) {
      if (app.needsOnboarding) {
        return const BudgetSetupScreen();
      }
      return const RootShell();
    }
    return const LoginScreen();
  }
}
