// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../app_state.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final TransactionItem transaction;

  const ExpenseDetailScreen({super.key, required this.transaction});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  late CategoryType _selectedCategory;
  late String _selectedSource;
  TransactionItem? _currentTransaction;

  TransactionItem get _transaction => _currentTransaction ?? widget.transaction;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _merchantCtrl = TextEditingController();
    _updateFromTransaction(widget.transaction);
  }

  void _updateFromTransaction(TransactionItem transaction) {
    _amountCtrl.text = transaction.amount.toString();
    _merchantCtrl.text = transaction.merchant;
    _selectedCategory = transaction.category;
    // Normalize source to match dropdown values
    final source = transaction.source.toLowerCase();
    if (source == 'upi') {
      _selectedSource = 'UPI';
    } else if (source == 'cash') {
      _selectedSource = 'Cash';
    } else if (source == 'card') {
      _selectedSource = 'Card';
    } else if (source == 'bank') {
      _selectedSource = 'Bank';
    } else {
      _selectedSource = source.isEmpty ? 'UPI' : source.substring(0, 1).toUpperCase() + source.substring(1).toLowerCase();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final app = AppScope.of(context);
    final amount = double.tryParse(_amountCtrl.text.trim());
    
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final merchant = _merchantCtrl.text.trim();
    if (merchant.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a merchant name')),
      );
      return;
    }

    try {
      // Convert source to lowercase for consistency
      final source = _selectedSource.toLowerCase();
      await app.updateTransaction(
        id: _transaction.id,
        amount: amount,
        category: _selectedCategory,
        merchant: merchant,
        source: source,
      );
      
      if (!mounted) return;
      
      // Get updated transaction from app state
      final updated = app.transactions.firstWhere(
        (t) => t.id == _transaction.id,
        orElse: () => _transaction,
      );
      
      setState(() {
        _currentTransaction = updated;
        _isEditing = false;
        _updateFromTransaction(updated);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update expense: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteExpense() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final app = AppScope.of(context);
    
    try {
      await app.removeTransaction(_transaction.id);
      
      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete expense: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteExpense,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amount',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      decoration: InputDecoration(
                        prefixText: '${app.currencySymbol} ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    Text(
                      formatCurrency(_transaction.amount, symbol: app.currencySymbol),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: app.categories.map((c) {
                        return ChoiceChip(
                          avatar: Icon(c.icon, size: 18),
                          label: Text(c.name),
                          selected: _selectedCategory == c.type,
                          onSelected: (_) => setState(() => _selectedCategory = c.type),
                        );
                      }).toList(),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          app.categories
                              .firstWhere((c) => c.type == _transaction.category)
                              .icon,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          app.categories
                              .firstWhere((c) => c.type == _transaction.category)
                              .name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Merchant Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merchant / Note',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    TextField(
                      controller: _merchantCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    Text(
                      _transaction.merchant,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Date & Source Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Theme.of(context).hintColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                          ),
                          Text(
                            '${_transaction.time.day}/${_transaction.time.month}/${_transaction.time.year}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.payment, size: 20, color: Theme.of(context).hintColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Source',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).hintColor,
                                ),
                          ),
                          if (_isEditing)
                            DropdownButton<String>(
                              value: _selectedSource,
                              items: ['UPI', 'Cash', 'Card', 'Bank', 'Other']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedSource = v ?? 'UPI'),
                            )
                          else
                            Text(
                              _transaction.source,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isEditing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _updateFromTransaction(_transaction);
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveChanges,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
