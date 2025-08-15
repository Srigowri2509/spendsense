// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/section.dart';
import '../widgets/donut_chart.dart';
import '../widgets/progress_bar.dart';
import '../widgets/gauge.dart';
import '../widgets/activity_tile.dart';
import 'spending_screen.dart';
import 'linked_banks_screen.dart';
import 'subscriptions_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    // Prepare donut data
    final donut = <Color, double>{};
    state.chartData.forEach((cat, value) => donut[cat.color] = value);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Home'),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
            ],
          ),
          SliverList.list(children: [
            Section(
              title: 'Monthly Spending',
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, SpendingScreen.route),
                child: const Text('View'),
              ),
              child: Row(
                children: [
                  DonutChart(
                    data: donut,
                    centerLabel: formatCurrency(state.totalSpentThisMonth),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: state.categories
                          .map((c) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(c.name)),
                                    Text(formatCurrency(state.spentFor(c.type))),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            Section(
              title: 'Emergency Fund',
              child: ProgressBar(
                value: (state.emergencySaved / state.emergencyTarget).clamp(0, 1),
                leftLabel: '${((state.emergencySaved / state.emergencyTarget) * 100).toStringAsFixed(0)}%',
                rightLabel: '${formatCurrency(state.emergencySaved)} / ${formatCurrency(state.emergencyTarget)}',
              ),
            ),
            Section(
              title: 'Luxuries',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gauge(value: (state.spentFor(CategoryType.luxuries) / 8000).clamp(0, 1)),
                  const SizedBox(height: 8),
                  Text('Keep luxuries below ${formatCurrency(8000)} this month.'),
                ],
              ),
            ),
            Section(
              title: 'Subscriptions',
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, SubscriptionsScreen.route),
                child: const Text('Manage'),
              ),
              child: Column(
                  children: state.subscriptions
                      .map((s) => ListTile(
                            leading: const Icon(Icons.subscriptions_outlined),
                            title: Text(s.name),
                            subtitle: Text('Due on ${s.billingDay}'),
                            trailing: Text(formatCurrency(s.amount)),
                          ))
                      .toList()),
            ),
            Section(
              title: 'Linked Banks',
              trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, LinkedBanksScreen.route),
                child: const Text('Edit'),
              ),
              child: Column(
                children: state.banks
                    .where((b) => b.linked)
                    .map((b) => Row(
                          children: [
                            CircleAvatar(child: Text(b.name.characters.first)),
                            const SizedBox(width: 12),
                            Expanded(child: Text('${b.name} • ${b.type}')),
                            const Icon(Icons.check_circle, color: Colors.green),
                          ],
                        ))
                    .toList(),
              ),
            ),
            Section(
              title: 'Recent Activity',
              child: Column(
                children: state.transactions
                    .take(6)
                    .map((t) => ActivityTile(item: t))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ],
      ),
    );
  }
}
