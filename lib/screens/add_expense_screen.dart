import 'package:flutter/material.dart';
import '../app_state.dart';

class AddExpenseScreen extends StatefulWidget {
  static const route = '/add';
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController amountC = TextEditingController();
  final TextEditingController merchantC = TextEditingController();
  CategoryType selected = CategoryType.food;

  @override
  void dispose() {
    amountC.dispose();
    merchantC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: amountC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CategoryType>(
              value: selected,
              items: CategoryType.values.map((e) {
                return DropdownMenuItem(value: e, child: Text(e.name[0].toUpperCase() + e.name.substring(1)));
              }).toList(),
              onChanged: (v) => setState(() => selected = v ?? selected),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: merchantC,
              decoration: const InputDecoration(labelText: 'Merchant / Note'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final amount = double.tryParse(amountC.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                  return;
                }
                state.addExpense(amount: amount, category: selected, merchant: merchantC.text.trim().isEmpty ? 'Expense' : merchantC.text.trim());
                amountC.clear();
                merchantC.clear();
                FocusScope.of(context).unfocus();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense added')));
              },
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
