// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/colorful_background.dart';
import '../widgets/empty_state.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthYear = '${monthNames[now.month - 1]} ${now.year}';

    // Check if we have any transactions this month
    final hasTransactions = app.transactions.any((t) => 
      t.time.year == now.year && t.time.month == now.month
    );

    return ColorfulBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Statistics for $monthYear'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: hasTransactions
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _AverageDailyCard(app: app),
                  const SizedBox(height: 12),
                  _HighLowExpensesRow(app: app),
                  const SizedBox(height: 12),
                  _MostFrequentMerchantCard(app: app),
                  const SizedBox(height: 12),
                  _SpendingByDayCard(app: app),
                ],
              )
            : EmptyState(
                icon: Icons.analytics_outlined,
                title: 'Not enough data',
                message: 'Add more expenses to see detailed statistics and insights',
                actionLabel: 'Add Expense',
                onAction: () => Navigator.pop(context),
              ),
      ),
    );
  }
}

class _AverageDailyCard extends StatelessWidget {
  final AppState app;
  const _AverageDailyCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final avgDaily = app.averageDailySpending;
    final dailyBudget = app.monthlyBudget / 30;
    final isOnTrack = avgDaily <= dailyBudget;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Average Daily Spending',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formatCurrency(avgDaily, symbol: app.currencySymbol),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOnTrack ? Icons.check_circle : Icons.warning,
                  size: 16,
                  color: isOnTrack ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  isOnTrack ? 'On track with budget' : 'Above daily budget',
                  style: TextStyle(
                    color: isOnTrack ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HighLowExpensesRow extends StatelessWidget {
  final AppState app;
  const _HighLowExpensesRow({required this.app});

  @override
  Widget build(BuildContext context) {
    final highest = app.highestExpense;
    final lowest = app.lowestExpense;

    return Row(
      children: [
        Expanded(
          child: _ExpenseCard(
            title: 'Highest Expense',
            icon: Icons.arrow_upward,
            iconColor: Colors.red,
            transaction: highest,
            currencySymbol: app.currencySymbol,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ExpenseCard(
            title: 'Lowest Expense',
            icon: Icons.arrow_downward,
            iconColor: Colors.green,
            transaction: lowest,
            currencySymbol: app.currencySymbol,
          ),
        ),
      ],
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final TransactionItem? transaction;
  final String currencySymbol;

  const _ExpenseCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.transaction,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (transaction != null) ...[
              Text(
                formatCurrency(transaction!.amount, symbol: currencySymbol),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                transaction!.merchant,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${transaction!.time.day}/${transaction!.time.month}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ] else
              Text(
                'N/A',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).hintColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _MostFrequentMerchantCard extends StatelessWidget {
  final AppState app;
  const _MostFrequentMerchantCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final merchant = app.mostFrequentMerchant;
    
    if (merchant == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final merchantTransactions = app.transactions.where((t) =>
      t.merchant == merchant &&
      t.time.year == now.year &&
      t.time.month == now.month
    ).toList();
    
    final count = merchantTransactions.length;
    final total = merchantTransactions.fold(0.0, (sum, t) => sum + t.amount);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Most Frequent Merchant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              merchant,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$count transactions',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  '•',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  formatCurrency(total, symbol: app.currencySymbol),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpendingByDayCard extends StatelessWidget {
  final AppState app;
  const _SpendingByDayCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final spendingByDay = app.spendingByDayOfWeek;
    final maxSpending = spendingByDay.values.reduce((a, b) => a > b ? a : b);
    
    // Find which day has highest spending
    String? highestDay;
    if (maxSpending > 0) {
      highestDay = spendingByDay.entries
          .firstWhere((e) => e.value == maxSpending)
          .key;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Spending by Day of Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: spendingByDay.entries.map((entry) {
                final height = maxSpending > 0 ? (entry.value / maxSpending * 120).clamp(4.0, 120.0) : 4.0;
                final isHighest = entry.key == highestDay;
                
                return Column(
                  children: [
                    Text(
                      formatCurrency(entry.value, symbol: ''),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: isHighest ? FontWeight.w700 : FontWeight.normal,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        color: isHighest
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: isHighest ? FontWeight.w700 : FontWeight.normal,
                          ),
                    ),
                  ],
                );
              }).toList(),
            ),
            if (highestDay != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You spend most on ${highestDay}s',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
