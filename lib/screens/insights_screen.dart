// ignore_for_file: prefer_const_constructors
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/colorful_background.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool showBar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).markBingoEvent('insights_viewed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    String money(num n) => formatCurrency(n, symbol: app.currencySymbol);

    return ColorfulBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/statistics'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.analytics_outlined, size: 32),
                            const SizedBox(height: 8),
                            Text('Statistics', style: Theme.of(context).textTheme.labelLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () => Navigator.pushNamed(context, '/transactions'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 32),
                            const SizedBox(height: 8),
                            Text('All Transactions', style: Theme.of(context).textTheme.labelLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Spending Mix
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Spending Mix', style: Theme.of(context).textTheme.titleLarge),
                        Spacer(),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Donut'), icon: Icon(Icons.donut_large)),
                            ButtonSegment(value: true, label: Text('Bar'), icon: Icon(Icons.bar_chart)),
                          ],
                          selected: {showBar},
                          onSelectionChanged: (s) => setState(() => showBar = s.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!showBar) // DONUT: legend at the side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: _Donut(
                              values: app.categories.map((c) => app.spentFor(c.type)).toList(),
                              colors: app.categories.map((c) => c.color).toList(),
                              center: money(app.totalSpentThisMonth),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: app.categories
                                  .map((c) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Container(width: 12, height: 12, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                            Text(money(app.spentFor(c.type))),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      )
                    else // BAR: labels below
                      Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: _MiniBar(
                              values: app.categories.map((c) => app.spentFor(c.type)).toList(),
                              colors: app.categories.map((c) => c.color).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: app.categories
                                .map((c) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 10, height: 10, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(c.name),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Monthly calendar heat (with current month)
            _MonthlyCalendarHeat(),

            const SizedBox(height: 12),

            // Yearly trend (bar)
            _YearlyTrend(),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== small charts =====
class _Donut extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final String center;
  const _Donut({required this.values, required this.colors, required this.center});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: _DonutPainter(values, colors))),
        Text(center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0.0, (a, b) => a + b);
    if (total <= 0) return;
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * .35;
    final center = size.center(Offset.zero);
    var start = -math.pi / 2;
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = stroke;
    for (var i = 0; i < values.length; i++) {
      p.color = colors[i % colors.length];
      final sweep = values[i] / total * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - stroke / 2), start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values || old.colors != colors;
}

class _MiniBar extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  const _MiniBar({required this.values, required this.colors});
  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<double>(1, (m, v) => v > m ? v : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: (values[i] / maxV * 150).clamp(4, 150),
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ===== calendar + yearly trend =====
class _MonthlyCalendarHeat extends StatelessWidget {
  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);

    final perDay = List<double>.filled(days, 0);
    for (final t in app.transactions.where((t) => t.time.year == now.year && t.time.month == now.month)) {
      perDay[t.time.day - 1] += t.amount;
    }
    final maxV = perDay.fold<double>(1, (m, v) => v > m ? v : m);

    Color heat(double v) {
      final x = (v / maxV);
      if (x < .33) return Colors.green.shade400;
      if (x < .66) return Colors.orange.shade500;
      return Colors.red.shade500;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Spend Calendar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('${_months[now.month - 1]} ${now.year}',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int d = 1; d <= days; d++)
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: perDay[d - 1] == 0 ? Theme.of(context).colorScheme.surfaceVariant : heat(perDay[d - 1]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$d'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                _LegendDot(color: Colors.green, label: 'Low'),
                SizedBox(width: 16),
                _LegendDot(color: Colors.orange, label: 'Medium'),
                SizedBox(width: 16),
                _LegendDot(color: Colors.red, label: 'High'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label),
    ]);
  }
}

class _YearlyTrend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final months = List<double>.filled(12, 0);
    for (final t in app.transactions) {
      if (t.time.year == DateTime.now().year) months[t.time.month - 1] += t.amount;
    }
    final maxV = months.fold<double>(1, (m, v) => v > m ? v : m);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yearly Spend Trend', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < 12; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          height: (months[i] / maxV * 150).clamp(2, 150),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
