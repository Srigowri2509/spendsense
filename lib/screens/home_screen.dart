// lib/screens/home_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    String money(num n) => formatCurrency(n, symbol: app.currencySymbol);

    // emergency wallet → progress
    final emg = app.walletById('emg');
    final double emgPct =
        emg.target <= 0 ? 0 : (emg.balance / emg.target).clamp(0.0, 1.0);

    // budget left dial
    final double left = app.moneyLeftToSpend;
    final double ratioLeft = app.moneyLeftRatio; // 0..1 (left/budget)
    final double used = (1 - ratioLeft).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ===== Brand =====
            Center(
              child: Column(
                children: [
                  Text(
                    'SpendSense',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(.18),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text('Spend smart. Live better.',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: Theme.of(context).hintColor)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== Donut + legend in a tinted panel =====
            _Panel(
              color: cs.secondaryContainer.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? .22 : .45,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: _DonutChart(
                      values: app.categories
                          .map((c) => app.spentFor(c.type))
                          .toList(),
                      colors: app.categories.map((c) => c.color).toList(),
                      centerText: money(app.totalSpentThisMonth),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: app.categories
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _LegendRow(
                                color: c.color,
                                // rename Rent → Necessities (label only)
                                label: c.type == CategoryType.rent
                                    ? 'Necessities'
                                    : c.name,
                                amount: money(app.spentFor(c.type)),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== Emergency Fund card with "REMINDER" =====
            _Panel(
              title: 'EMERGENCY FUNDS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: emgPct,
                      minHeight: 14,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Reminder(
                    text: emg.target <= 0
                        ? 'Set a goal to start tracking your emergency fund.'
                        : (emg.balance >= emg.target)
                            ? 'Goal reached! Great job building your cushion.'
                            : 'You need ${money(emg.target - emg.balance)} more to complete the goal.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== Money left dial (green -> red) with REMINDER =====
            _Panel(
              title: 'MONEY LEFT TO SPEND',
              child: Row(
                children: [
                  _DialGauge(
                    ratio: ratioLeft,
                    size: 150,
                    color: _colorFromUsage(used),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${money(left)} left',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('of ${money(app.monthlyBudget)} this month'),
                        const SizedBox(height: 10),
                        _Reminder(
                          text: left >= 0
                              ? 'REMINDER: You have ${money(left)} left for this month.'
                              : 'REMINDER: Over budget by ${money(left.abs())}.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== Bingo / Tasks (Daily • Weekly • Monthly) =====
            _Panel(
              title: 'BINGO — DAILY • WEEKLY • MONTHLY',
              child: _BingoPanel(),
            ),

            const SizedBox(height: 14),

            // ===== Quick actions (as in mock) =====
            _Panel(
              title: 'Quick actions',
              child: _QuickActions(
                actions: const [
                  _QA(icon: Icons.add, label: 'Expense'),
                  _QA(icon: Icons.account_balance, label: 'Link bank'),
                  _QA(icon: Icons.attach_money, label: 'Salary credit'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Upcoming bills (top 3) =====
            if (app.upcomingBills.isNotEmpty) ...[
              Text('Upcoming bills',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _Panel(
                child: Column(
                  children: [
                    for (final it in app.upcomingBills) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_note_outlined),
                        title: Text(it.sub.name),
                        subtitle:
                            Text('Due ${_fmtDay(it.due)} • ${money(it.sub.amount)}'),
                      ),
                      if (it != app.upcomingBills.last)
                        const Divider(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

/// ======= Reusable tinted panel =======
class _Panel extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color? color;
  const _Panel({this.title, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ??
            cs.surfaceContainerHighest
                .withOpacity(Theme.of(context).brightness == Brightness.dark ? .4 : .7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _Reminder extends StatelessWidget {
  final String text;
  const _Reminder({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
          Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// ======= Donut + legend =======
class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  const _LegendRow({required this.color, required this.label, required this.amount});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700))),
        Text(amount, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final String? centerText;
  const _DonutChart({required this.values, required this.colors, this.centerText});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: _DonutPainter(values, colors))),
        if (centerText != null)
          Text(centerText!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * 0.35;

    var start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.values != values || old.colors != colors;
}

/// ======= Dial gauge (budget left) =======
class _DialGauge extends StatelessWidget {
  final double ratio; // 0..1 (left/budget)
  final double size;
  final Color color;
  const _DialGauge({required this.ratio, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final r = ratio.clamp(0.0, 1.0).toDouble();
    final track = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DialPainter(ratio: r, color: color, trackColor: track),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${(r * 100).round()}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('left', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double ratio; // 0..1
  final Color color;
  final Color trackColor;
  _DialPainter({required this.ratio, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * 0.18;

    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bg);

    final sweep = ratio * 2 * math.pi;
    if (sweep > 0) canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.ratio != ratio || old.color != color || old.trackColor != trackColor;
}

Color _colorFromUsage(double used) {
  used = used.clamp(0.0, 1.0);
  Color a, b;
  double t;
  if (used <= 0.5) {
    a = const Color(0xFF4CAF50); // green
    b = const Color(0xFFFFC107); // amber
    t = used / 0.5;
  } else {
    a = const Color(0xFFFFC107);
    b = const Color(0xFFF44336);
    t = (used - 0.5) / 0.5;
  }
  return Color.lerp(a, b, t)!;
}

/// ======= Bingo panel (daily / weekly / monthly) =======
class _BingoPanel extends StatefulWidget {
  @override
  State<_BingoPanel> createState() => _BingoPanelState();
}

class _BingoPanelState extends State<_BingoPanel> {
  String _tab = 'daily'; // daily | weekly | monthly
  // simple 3x3 boolean boards
  final Map<String, List<bool>> _boards = {
    'daily': List<bool>.filled(9, false),
    'weekly': List<bool>.filled(9, false),
    'monthly': List<bool>.filled(9, false),
  };

  // demo labels per tab (9 each)
  final Map<String, List<String>> _labels = {
    'daily': [
      'Add expense','No-spend day','Open insights',
      'Log breakfast','Review wallet','Skip cab',
      'Use coupon','Drink water','Walk 3k'
    ],
    'weekly': [
      'Under budget','Check bills','Update goals',
      'Review subs','Transfer save','Plan meals',
      'Track travel','Set reminder','Clean wallet'
    ],
    'monthly': [
      'Set budgets','Reset puzzle','Credit salary',
      'Export data','Audit spend','Tweak targets',
      'Pay rent','Review trends','Donate spare'
    ],
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'daily', label: Text('Daily')),
            ButtonSegment(value: 'weekly', label: Text('Weekly')),
            ButtonSegment(value: 'monthly', label: Text('Monthly')),
          ],
          selected: {_tab},
          onSelectionChanged: (s) => setState(() => _tab = s.first),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: 9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .95,
          ),
          itemBuilder: (_, i) {
            final checked = _boards[_tab]![i];
            return InkWell(
              onTap: () => _toggle(i),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: checked ? cs.primaryContainer : cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: checked ? cs.primary : cs.outlineVariant),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(checked ? Icons.check_circle : Icons.circle_outlined,
                        color: checked ? cs.primary : cs.onSurfaceVariant),
                    const SizedBox(height: 6),
                    Text(
                      _labels[_tab]![i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: checked ? cs.onPrimaryContainer : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _toggle(int i) {
    final app = AppScope.of(context);
    final board = _boards[_tab]!;
    setState(() => board[i] = !board[i]);

    if (_isBingo(board)) {
      // celebrate & count
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bingo! 🎉')),
      );
      app.incrementPuzzleCompleted();
      // (optional) reset board after success:
      // setState(() => _boards[_tab] = List<bool>.filled(9, false));
    }
  }

  bool _isBingo(List<bool> b) {
    const lines = <List<int>>[
      // rows
      [0,1,2],[3,4,5],[6,7,8],
      // cols
      [0,3,6],[1,4,7],[2,5,8],
      // diags
      [0,4,8],[2,4,6],
    ];
    for (final line in lines) {
      if (b[line[0]] && b[line[1]] && b[line[2]]) return true;
    }
    return false;
  }
}

/// ======= Quick actions =======
class _QA {
  final IconData icon;
  final String label;
  const _QA({required this.icon, required this.label});
}

class _QuickActions extends StatelessWidget {
  final List<_QA> actions;
  const _QuickActions({required this.actions});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions
          .map((a) => Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: Icon(a.icon),
                  ),
                  const SizedBox(height: 6),
                  Text(a.label),
                ],
              ))
          .toList(),
    );
  }
}

// alias so main.dart can use either name
typedef HomePage = HomeScreen;
String formatCurrency(num amount, {String symbol = '\$'}) {
  return '$symbol${amount.toStringAsFixed(2)}';
}