// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../app_state.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountCtrl = TextEditingController();
  final merchantCtrl = TextEditingController();
  CategoryType selected = CategoryType.food;

  @override
  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Amount hero input
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amount', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: .3),
                    decoration: InputDecoration(
                      prefixText: '${app.currencySymbol} ',
                      hintText: '0',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category chips
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  for (final c in app.categories)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: selected == c.type,
                      onSelected: (_) => setState(() => selected = c.type),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Merchant / note
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: TextField(
                controller: merchantCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merchant / Note',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quick suggestions row
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Suggest('Swiggy', () => merchantCtrl.text = 'Swiggy'),
                _Suggest('Uber', () => merchantCtrl.text = 'Uber'),
                _Suggest('Big Bazaar', () => merchantCtrl.text = 'Big Bazaar'),
                _Suggest('Zomato', () => merchantCtrl.text = 'Zomato'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Save button
          FilledButton.icon(
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text.trim());
              if (amt == null || amt <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                return;
              }
              final merchant = merchantCtrl.text.trim().isEmpty ? 'Unknown' : merchantCtrl.text.trim();
              app.addExpense(amount: amt, category: selected, merchant: merchant);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${formatCurrency(amt)} to ${selected.name}')));
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _Suggest extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Suggest(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
        child: Text(label),
      ),
    );
  }
}
