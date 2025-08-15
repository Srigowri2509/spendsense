import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/section.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart.dart';


class InsightsScreen extends StatelessWidget {
  static const route = '/insights';
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final donut = <Color, double>{};
    state.chartData.forEach((cat, value) => donut[cat.color] = value);

    // Fake monthly series (use your own analytics later)
    final months = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];
    final vals = [9, 11, 16, 13, 18, 15, state.totalSpentThisMonth / 1000].map((e) => e.toDouble()).toList();

    // Example insight
    final coffeeNote = 'You spent 38% more on coffee than last month';

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        children: [
          Section(
            title: 'Spending Mix',
            child: Row(
              children: [
                DonutChart(data: donut, centerLabel: formatCurrency(state.totalSpentThisMonth)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    coffeeNote,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          Section(
            title: 'Trend',
            child: SimpleBarChart(values: vals, labels: months),
          ),
          Section(
            title: 'Tips',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ListTile(
                  leading: Icon(Icons.lightbulb_outline),
                  title: Text('Try batch-cooking weekends to cut Food costs by 10–15%.'),
                ),
                ListTile(
                  leading: Icon(Icons.train_outlined),
                  title: Text('Switch 2 ride-hails to metro this week and save ₹300+.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
