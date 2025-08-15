import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/section.dart';
import '../widgets/donut_chart.dart';

class SpendingScreen extends StatelessWidget {
  static const route = '/spending';
  const SpendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final donut = <Color, double>{};
    state.chartData.forEach((cat, value) => donut[cat.color] = value);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Spending')),
      body: ListView(
        children: [
          Section(
            title: 'Overview',
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(width: 10, height: 10, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(c.name)),
                                  Text('${formatCurrency(state.spentFor(c.type))} / ${formatCurrency(c.monthlyBudget)}'),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                )
              ],
            ),
          ),
          ...state.categories.map((c) {
            final items = state.transactions.where((t) => t.category == c.type).toList()
              ..sort((a, b) => b.time.compareTo(a.time));
            return Section(
              title: c.name,
              child: Column(
                children: items
                    .map((t) => ListTile(
                          leading: CircleAvatar(backgroundColor: c.color.withOpacity(.2), child: Icon(Icons.payments, color: c.color)),
                          title: Text(t.merchant),
                          subtitle: Text('${t.source} • ${t.time.day}/${t.time.month}'),
                          trailing: Text('- ${formatCurrency(t.amount)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
            );
          })
        ],
      ),
    );
  }
}
