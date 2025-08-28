// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (app.isSignedIn) {
      // Already signed in → straight into the app shell
      return const RootShell();
    }
    return const _WelcomeLogin();
  }
}

class _WelcomeLogin extends StatefulWidget {
  const _WelcomeLogin();

  @override
  State<_WelcomeLogin> createState() => _WelcomeLoginState();
}

class _WelcomeLoginState extends State<_WelcomeLogin> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final nickCtrl = TextEditingController();
  String gender = 'unspecified';

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    nickCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const SizedBox(height: 20),
            Center(child: Text('SpendSense', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
            const SizedBox(height: 6),
            Center(child: Text('Spend smart. Live better.', style: Theme.of(context).textTheme.labelLarge)),
            const SizedBox(height: 24),

            // Cute intro card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Text('🐣', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Let’s set you up. Sign in or try Guest mode (limited features).')),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: nickCtrl, decoration: const InputDecoration(labelText: 'Nickname (optional)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: gender,
              items: const [
                DropdownMenuItem(value: 'unspecified', child: Text('Prefer not to say')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'male', child: Text('Male')),
              ],
              onChanged: (v) => setState(() => gender = v ?? 'unspecified'),
              decoration: const InputDecoration(labelText: 'Gender'),
            ),

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final app = AppScope.of(context);
                app.signInDemo(
                  name: nameCtrl.text.trim().isEmpty ? 'Guest' : nameCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? 'guest@example.com' : emailCtrl.text.trim(),
                  nick: nickCtrl.text.trim(),
                );
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RootShell()));
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign in / Sign up'),
            ),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Guest: stay not signed in, continue to shell
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RootShell()));
              },
              icon: const Icon(Icons.person),
              label: const Text('Continue as Guest (limited)'),
            ),

            const SizedBox(height: 12),
            Text('Guest mode disables bank linking; you can still add expenses manually.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline)),
          ],
        ),
      ),
    );
  }
}
