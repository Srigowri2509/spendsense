import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/subscription.dart';
import '../widgets/empty_state.dart';

class SubscriptionsScreen extends StatefulWidget {
  static const route = '/subscriptions';
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SubscriptionCategory? _selectedCategory;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).markBingoEvent('subscriptions_viewed');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Subscription> _getFilteredSubscriptions(AppState app) {
    List<Subscription> subs;
    
    switch (_tabController.index) {
      case 0:
        subs = app.subscriptions;
        break;
      case 1:
        subs = app.upcomingSubscriptions;
        break;
      case 2:
        subs = app.overdueSubscriptions;
        break;
      default:
        subs = app.subscriptions;
    }

    if (_selectedCategory != null) {
      subs = subs.where((s) => s.category == _selectedCategory).toList();
    }

    return subs;
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final billingDayController = TextEditingController();
    BillingCycle selectedCycle = BillingCycle.monthly;
    SubscriptionCategory selectedCategory = SubscriptionCategory.other;
    DateTime selectedStartDate = DateTime.now();
    bool isFixed = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Name',
                    hintText: 'e.g., Netflix, Spotify',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BillingCycle>(
                  value: selectedCycle,
                  decoration: const InputDecoration(
                    labelText: 'Billing Cycle',
                  ),
                  items: BillingCycle.values.map((cycle) {
                    return DropdownMenuItem(
                      value: cycle,
                      child: Text(cycle.name[0].toUpperCase() + cycle.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCycle = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    '${selectedStartDate.day}/${selectedStartDate.month}/${selectedStartDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedStartDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: billingDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Billing Day (1-31)',
                    hintText: 'Day of month when billed',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SubscriptionCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                  items: SubscriptionCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Count as fixed expense'),
                  value: isFixed,
                  onChanged: (value) => setState(() => isFixed = value),
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
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                final billingDay = int.tryParse(billingDayController.text.trim());

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a subscription name')),
                  );
                  return;
                }

                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                if (billingDay == null || billingDay < 1 || billingDay > 31) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid billing day (1-31)')),
                  );
                  return;
                }

                final app = AppScope.of(context);
                await app.addSubscription(
                  name: name,
                  amount: amount,
                  billingCycle: selectedCycle,
                  startDate: selectedStartDate,
                  billingDay: billingDay,
                  isFixed: isFixed,
                  category: selectedCategory,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added subscription: $name')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSubscriptionDialog(BuildContext context, Subscription subscription) {
    final nameController = TextEditingController(text: subscription.name);
    final amountController = TextEditingController(text: subscription.amount.toString());
    final billingDayController = TextEditingController(text: subscription.billingDay.toString());
    BillingCycle selectedCycle = subscription.billingCycle;
    SubscriptionCategory selectedCategory = subscription.category;
    bool isFixed = subscription.isFixed;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Subscription'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Subscription Name'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BillingCycle>(
                  value: selectedCycle,
                  decoration: const InputDecoration(labelText: 'Billing Cycle'),
                  items: BillingCycle.values.map((cycle) {
                    return DropdownMenuItem(
                      value: cycle,
                      child: Text(cycle.name[0].toUpperCase() + cycle.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedCycle = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: billingDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Billing Day (1-31)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<SubscriptionCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: SubscriptionCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Count as fixed expense'),
                  value: isFixed,
                  onChanged: (value) => setState(() => isFixed = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Subscription?'),
                    content: Text('Are you sure you want to delete ${subscription.name}?'),
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

                if (confirmed == true && context.mounted) {
                  final app = AppScope.of(context);
                  await app.deleteSubscription(subscription.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Subscription deleted')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim());
                final billingDay = int.tryParse(billingDayController.text.trim());

                if (name.isEmpty || amount == null || amount <= 0 ||
                    billingDay == null || billingDay < 1 || billingDay > 31) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields correctly')),
                  );
                  return;
                }

                final app = AppScope.of(context);
                final updated = subscription.copyWith(
                  name: name,
                  amount: amount,
                  billingCycle: selectedCycle,
                  billingDay: billingDay,
                  isFixed: isFixed,
                  category: selectedCategory,
                );

                await app.updateSubscription(updated);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final filteredSubs = _getFilteredSubscriptions(app);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: Column(
        children: [
          if (app.subscriptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<SubscriptionCategory?>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Filter by Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ...SubscriptionCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.name[0].toUpperCase() + cat.name.substring(1)),
                    );
                  }),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ),
          Expanded(
            child: filteredSubs.isEmpty
                ? EmptyState(
                    icon: Icons.subscriptions_outlined,
                    title: _tabController.index == 2
                        ? 'No overdue subscriptions'
                        : _tabController.index == 1
                            ? 'No upcoming subscriptions'
                            : 'No subscriptions',
                    message: _tabController.index == 0
                        ? 'Track your recurring payments by adding subscriptions'
                        : 'All caught up!',
                    actionLabel: _tabController.index == 0 ? 'Add Subscription' : null,
                    onAction: _tabController.index == 0
                        ? () => _showAddSubscriptionDialog(context)
                        : null,
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...filteredSubs.map((sub) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(Icons.subscriptions_outlined, color: sub.statusColor),
                            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('₹${sub.amount.toStringAsFixed(0)}/${sub.billingCycleText.toLowerCase()}'),
                                const SizedBox(height: 4),
                                Text(
                                  '${sub.statusText} • ${sub.categoryText}',
                                  style: TextStyle(
                                    color: sub.statusColor,
                                    fontWeight: sub.isOverdue || sub.isDueToday ? FontWeight.w600 : null,
                                  ),
                                ),
                              ],
                            ),
                            trailing: sub.isFixed
                                ? const Chip(label: Text('Fixed'), labelStyle: TextStyle(fontSize: 10))
                                : null,
                            onTap: () => _showEditSubscriptionDialog(context, sub),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Card(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cost Summary',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _CostRow(label: 'Monthly', amount: app.totalMonthlyCost),
                              _CostRow(label: 'Quarterly', amount: app.totalQuarterlyCost),
                              _CostRow(label: 'Yearly', amount: app.totalYearlyCost),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubscriptionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final double amount;

  const _CostRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
