// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/colorful_background.dart';
import '../widgets/icon_picker.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountCtrl = TextEditingController();
  final merchantCtrl = TextEditingController();
  CategoryType selected = CategoryType.food;
  String source = 'upi';

  @override
  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return ColorfulBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Add Expense'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'upi', label: Text('UPI'), icon: Icon(Icons.phone_android)),
                        ButtonSegment(value: 'card', label: Text('Card'), icon: Icon(Icons.credit_card)),
                        ButtonSegment(value: 'cash', label: Text('Cash'), icon: Icon(Icons.payments)),
                      ],
                      selected: {source},
                      onSelectionChanged: (value) => setState(() => source = value.first),
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in app.categories)
                          ChoiceChip(
                            avatar: Icon(c.icon, size: 18),
                            label: Text(c.name),
                            selected: selected == c.type,
                            onSelected: (_) => setState(() => selected = c.type),
                          ),
                        // Add custom category button
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('Add Category'),
                          onPressed: () => _showAddCategoryDialog(context),
                        ),
                      ],
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
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim());
                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                  return;
                }
                final merchant = merchantCtrl.text.trim().isEmpty ? 'Unknown' : merchantCtrl.text.trim();

                try {
                  await app.addExpense(amount: amt, category: selected, merchant: merchant, source: source);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${formatCurrency(amt)} to ${selected.name}')));

                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      amountCtrl.clear();
                      merchantCtrl.clear();
                      selected = CategoryType.food;
                      source = 'upi';
                    });
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to add expense: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Custom Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g., Healthcare, Education',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                const Text('Choose Icon:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: IconPicker(
                    selectedIcon: selectedIcon,
                    onIconSelected: (icon) => setState(() => selectedIcon = icon),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.red,
                    Colors.pink,
                    Colors.purple,
                    Colors.blue,
                    Colors.cyan,
                    Colors.teal,
                    Colors.green,
                    Colors.lime,
                    Colors.yellow,
                    Colors.orange,
                    Colors.brown,
                    Colors.grey,
                  ].map((color) => InkWell(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? Colors.black : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selectedColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a category name')),
                  );
                  return;
                }
                final app = AppScope.of(context);
                app.addCustomCategory(name: name, color: selectedColor, icon: selectedIcon);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added category: $name')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
