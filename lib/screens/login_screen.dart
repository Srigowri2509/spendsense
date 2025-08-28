// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _nick = TextEditingController();

  @override
  void dispose() { _name.dispose(); _email.dispose(); _nick.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 8),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _nick, decoration: const InputDecoration(labelText: 'Nickname (optional)')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final name = _name.text.trim().isEmpty ? 'User' : _name.text.trim();
              final email = _email.text.trim().isEmpty ? 'user@example.com' : _email.text.trim();
              app.signInDemo(name: name, email: email, nick: _nick.text.trim());
              Navigator.pop(context);
            },
            icon: const Icon(Icons.login),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
