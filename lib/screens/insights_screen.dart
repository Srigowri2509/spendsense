import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart.dart';

enum ChartMode { donut, bar }

class InsightsScreen extends StatefulWidget {
  static const route = '/insights'; // <-- add this

  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  ChartMode mode = ChartMode.donut;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final donutData = <Color, double>{};
    for (final c in state.categories) { donutData[c.color] = state.spentFor(c.type); }

    final months = ['Feb','Mar','Apr','May','Jun','Jul','Aug'];
    final series = [12, 14, 28, 16, 18, 15, 42].map((e) => e.toDouble()).toList(); // demo trend

    final highest = state.categories.map((c) => MapEntry(c, state.spentFor(c.type))).toList()
      ..sort((a,b)=>b.value.compareTo(a.value));
    final topCat = highest.first;

    final recs = <String>[
      'Your highest spend is ${topCat.key.name}. Try setting a sub-budget there.',
      if (state.fixedMonthlyTotal > state.monthlySavingsTarget * 0.5)
        'Fixed commitments look heavy. Consider pausing a subscription.',
      if (state.spentFor(CategoryType.shopping) > state.spentFor(CategoryType.food))
        'Shopping beat Food this month — delay non-essentials to next month.',
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Spending Mix
          _CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Spending Mix', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  SegmentedButton<ChartMode>(
                    segments: const [
                      ButtonSegment(value: ChartMode.donut, icon: Icon(Icons.donut_large), label: Text('Donut')),
                      ButtonSegment(value: ChartMode.bar,   icon: Icon(Icons.bar_chart),   label: Text('Bar')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => setState(()=> mode = s.first),
                  ),
                ]),
                const SizedBox(height: 12),
                if (mode == ChartMode.donut)
                  Row(
                    children: [
                      DonutChart(
                        data: donutData,
                        size: 150,
                        centerLabel: formatCurrency(state.totalSpentThisMonth, symbol: state.currencySymbol),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text('You can switch layouts anytime — donut or bar.', style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  )
                else
                  SimpleBarChart(
                    values: donutData.values.toList(),
                    labels: state.categories.map((c)=>c.name.substring(0,3)).toList(),
                  ),
              ],
            ),
          ),

          // Trend
          _CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trend', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SimpleBarChart(values: series, labels: months),
              ],
            ),
          ),

          // Tips & Recommendations
          _CardBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommendations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...recs.map((r) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(r),
                )),
                const SizedBox(height: 4),
                Text('Once bank sync is live, we’ll tailor these from your real merchants and patterns.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final Widget child;
  const _CardBlock({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
