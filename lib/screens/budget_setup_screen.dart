import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _monthlyFormKey = GlobalKey<FormState>();
  final TextEditingController _monthlyController = TextEditingController();

  late AppState _app;
  final Map<String, TextEditingController> _categoryControllers = {};
  int _currentStep = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    if (_categoryControllers.isEmpty) {
      for (final category in _app.categories) {
        _categoryControllers[category.name] = TextEditingController(
          text: category.monthlyBudget > 0
              ? category.monthlyBudget.toStringAsFixed(0)
              : '',
        );
      }
      _monthlyController.text =
          _app.monthlyBudget > 0 ? _app.monthlyBudget.toStringAsFixed(0) : '';
    }
  }

  @override
  void dispose() {
    _monthlyController.dispose();
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Set Up Your Budgets'),
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          controlsBuilder: (context, details) {
            final isLast = _currentStep == 1;
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(isLast ? 'Finish' : 'Continue'),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
              ),
            );
          },
          onStepContinue: _handleContinue,
          onStepCancel: () {
            if (_currentStep == 0) return;
            setState(() => _currentStep -= 1);
          },
          steps: [
            Step(
              isActive: _currentStep == 0,
              title: const Text('Monthly budget'),
              content: Form(
                key: _monthlyFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is the total amount you aim to spend this month.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _monthlyController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      decoration: const InputDecoration(
                        labelText: 'Monthly budget',
                        prefixText: '₹ ',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a positive amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            Step(
              isActive: _currentStep == 1,
              title: const Text('Category limits'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Optional: Distribute your monthly budget across categories.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._app.categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: _categoryControllers[category.name],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: false),
                        decoration: InputDecoration(
                          labelText: '${category.name} limit',
                          prefixText: '₹ ',
                          suffixIcon: Icon(
                            category.icon,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      if (_monthlyFormKey.currentState?.validate() != true) return;
      setState(() => _currentStep = 1);
      return;
    }

    final monthly = int.parse(_monthlyController.text.trim());
    _app.setMonthlyBudget(monthly);

    for (final entry in _categoryControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) continue;
      final amount = int.tryParse(text);
      if (amount == null) continue;
      _app.setCategoryBudget(entry.key, amount);
    }

    _app.markOnboardingComplete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budgets saved!')),
    );

    // Once onboarding is complete, AuthGate will rebuild and show the app shell.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootShell()),
      (route) => false,
    );
  }
}

