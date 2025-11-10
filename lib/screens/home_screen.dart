// lib/screens/home_screen.dart
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../services/sms_parser.dart';
import '../services/sms_service.dart';
import '../services/transaction_import_service.dart';
import '../widgets/colorful_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _importScheduled = false;
  DateTime? _lastImportCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleFirstFrame());
    // Set up periodic auto-import (every 5 minutes when app is active)
    _startPeriodicImport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Run import when app comes to foreground
      final app = AppScope.of(context);
      _maybeAutoImport(app, showNotification: false);
    }
  }

  void _startPeriodicImport() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        final app = AppScope.of(context);
        _maybeAutoImport(app, showNotification: false);
        _startPeriodicImport(); // Schedule next check
      }
    });
  }

  Future<void> _handleFirstFrame() async {
    if (!mounted) return;
    final app = AppScope.of(context);
    app.markBingoEvent('home_viewed');
    if (_importScheduled) return;
    _importScheduled = true;
    await _maybeAutoImport(app);
  }

  Future<void> _maybeAutoImport(AppState app, {bool showNotification = true}) async {
    try {
      // Throttle: Don't check more than once per minute
      final now = DateTime.now();
      if (_lastImportCheck != null && 
          now.difference(_lastImportCheck!).inMinutes < 1) {
        return;
      }
      _lastImportCheck = now;

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('sms_import_enabled') ?? true;
      if (!enabled) return;

      const smsService = SmsService();
      if (!await smsService.hasPermission()) return;

      final importer = TransactionImportService(
        smsService,
        SmsParser(),
        app,
      );

      await importer.loadImportHistory();
      
      // Only scan last 1 day for periodic checks (faster)
      final daysBack = showNotification ? (prefs.getInt('sms_days_back') ?? 30) : 1;
      final pending = await importer.scanTransactions(daysBack: daysBack);
      if (pending.isEmpty) return;

      final result = await importer.importTransactions(pending);
      if (!mounted) return;
      if (result.successful > 0) {
        app.markBingoEvent('receipt_saved');
        if (showNotification && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Imported ${result.successful} expense${result.successful > 1 ? 's' : ''} from SMS'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Auto SMS import failed: $e');
    }
  }

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

    final children = <Widget>[
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
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Spend smart. Live better.',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _Panel(
        color: cs.secondaryContainer
            .withOpacity(Theme.of(context).brightness == Brightness.dark ? .22 : .45),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: _DonutChart(
                values: app.categories.map((c) => app.spentFor(c.type)).toList(),
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
                          label: c.type == CategoryType.rent ? 'Necessities' : c.name,
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
                  Text(
                    '${money(left)} left',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
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
      _Panel(
        title: 'BINGO — DAILY • WEEKLY • MONTHLY',
        child: _BingoPanel(),
      ),
      const SizedBox(height: 16),
      if (app.upcomingBills.isNotEmpty) ...[
        Text('Upcoming bills', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _Panel(
          child: Column(
            children: [
              for (final it in app.upcomingBills) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_note_outlined),
                  title: Text(it.sub.name),
                  subtitle: Text('Due ${_fmtDay(it.due)} • ${money(it.sub.amount)}'),
                ),
                if (it != app.upcomingBills.last)
                  const Divider(height: 8),
              ],
            ],
          ),
        ),
      ],
    ];

    return ColorfulBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: children,
          ),
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
  String _tab = 'daily';
  final Map<String, int> _lastCompletedCount = {'daily': 0, 'weekly': 0, 'monthly': 0};

  // Check if 3 tasks connect horizontally, vertically, or diagonally
  bool _isBingo(List<bool> filled) {
    const lines = [
      [0, 1, 2], // row 1 (horizontal)
      [3, 4, 5], // row 2 (horizontal)
      [6, 7, 8], // row 3 (horizontal)
      [0, 3, 6], // col 1 (vertical)
      [1, 4, 7], // col 2 (vertical)
      [2, 5, 8], // col 3 (vertical)
      [0, 4, 8], // diag 1 (top-left to bottom-right)
      [2, 4, 6], // diag 2 (top-right to bottom-left)
    ];
    for (final line in lines) {
      // Check if all 3 positions in this line are filled
      if (filled[line[0]] && filled[line[1]] && filled[line[2]]) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkBingo();
    });
  }

  @override
  void didUpdateWidget(_BingoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkBingo();
    });
  }

  void _checkBingo() {
    if (!mounted) return;
    final app = AppScope.of(context);
    final tasks = _taskMap[_tab]!;
    final filled = List<bool>.generate(9, (i) => i < tasks.length ? tasks[i].isComplete(app) : false);
    final completed = filled.where((f) => f).length;
    final lastCount = _lastCompletedCount[_tab] ?? 0;

    if (completed > lastCount && _isBingo(filled)) {
      app.incrementPuzzleCompleted();
      app.rewardPoints += 20;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bingo! 🎉 +20 points')),
        );
      }
    }
    _lastCompletedCount[_tab] = completed;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final tasks = _taskMap[_tab]!;
    final completed = tasks.where((t) => t.isComplete(app)).length;

    // Check for bingo when completed count changes
    final lastCount = _lastCompletedCount[_tab] ?? 0;
    if (completed != lastCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkBingo();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ],
              selected: {_tab},
              onSelectionChanged: (s) {
                setState(() => _tab = s.first);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _checkBingo();
                });
              },
            ),
            Text(
              '$completed / ${tasks.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: tasks.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: .95,
          ),
          itemBuilder: (_, index) {
            final task = tasks[index];
            final done = task.isComplete(app);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: done
                    ? LinearGradient(
                        colors: [
                          cs.primary.withOpacity(.85),
                          cs.secondary.withOpacity(.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: done ? null : cs.surface.withOpacity(.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: done ? cs.primary : cs.outlineVariant,
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    done ? Icons.check_circle : task.icon,
                    color: done ? cs.onPrimary : cs.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: done ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AutoTask {
  final String id;
  final String label;
  final IconData icon;
  final bool Function(AppState app) isComplete;

  const _AutoTask({
    required this.id,
    required this.label,
    required this.icon,
    required this.isComplete,
  });
}

final Map<String, List<_AutoTask>> _taskMap = {
  'daily': [
    _AutoTask(
      id: 'daily_add_expense',
      label: 'Add expense',
      icon: Icons.add_task,
      isComplete: (app) => app.didAddExpenseToday,
    ),
    _AutoTask(
      id: 'daily_no_spend',
      label: 'No-spend day',
      icon: Icons.hourglass_bottom,
      isComplete: (app) => app.noSpendToday,
    ),
    _AutoTask(
      id: 'daily_check_insights',
      label: 'Check insights',
      icon: Icons.insights,
      isComplete: (app) => app.didEventToday('insights_viewed'),
    ),
    _AutoTask(
      id: 'daily_review_budget',
      label: 'Review budget',
      icon: Icons.pie_chart,
      isComplete: (app) =>
          app.didEventToday('spending_viewed') ||
          app.didEventToday('budget_updated'),
    ),
    _AutoTask(
      id: 'daily_skip_delivery',
      label: 'Skip delivery',
      icon: Icons.delivery_dining,
      isComplete: (app) => app.avoidedDeliveryToday,
    ),
    _AutoTask(
      id: 'daily_use_cash',
      label: 'Use cash',
      icon: Icons.payments,
      isComplete: (app) => app.usedCashToday,
    ),
    _AutoTask(
      id: 'daily_compare_prices',
      label: 'Compare prices',
      icon: Icons.receipt_long,
      isComplete: (app) => app.didEventToday('transactions_viewed'),
    ),
    _AutoTask(
      id: 'daily_pack_lunch',
      label: 'Pack lunch',
      icon: Icons.lunch_dining,
      isComplete: (app) =>
          app.spentInLastDays(1, category: CategoryType.food) <= 200,
    ),
    _AutoTask(
      id: 'daily_walk_instead',
      label: 'Walk instead',
      icon: Icons.directions_walk,
      isComplete: (app) =>
          app.spentInLastDays(1, category: CategoryType.travel) == 0,
    ),
  ],
  'weekly': [
    _AutoTask(
      id: 'weekly_under_budget',
      label: 'Stay under budget',
      icon: Icons.speed,
      isComplete: (app) => app.isUnderBudgetForPeriod(7),
    ),
    _AutoTask(
      id: 'weekly_review_bills',
      label: 'Review bills',
      icon: Icons.receipt,
      isComplete: (app) =>
          app.didEventWithin('subscriptions_viewed', const Duration(days: 7)),
    ),
    _AutoTask(
      id: 'weekly_update_goals',
      label: 'Update goals',
      icon: Icons.flag,
      isComplete: (app) =>
          app.didEventWithin('goals_updated', const Duration(days: 7)),
    ),
    _AutoTask(
      id: 'weekly_check_subscriptions',
      label: 'Check subscriptions',
      icon: Icons.subscriptions,
      isComplete: (app) =>
          app.didEventWithin('subscriptions_viewed', const Duration(days: 7)),
    ),
    _AutoTask(
      id: 'weekly_plan_meals',
      label: 'Plan meals',
      icon: Icons.restaurant_menu,
      isComplete: (app) => !app.hadDeliveryInLastDays(7),
    ),
    _AutoTask(
      id: 'weekly_track_spending',
      label: 'Track spending',
      icon: Icons.assessment,
      isComplete: (app) =>
          app.didEventWithin('transactions_viewed', const Duration(days: 7)),
    ),
    _AutoTask(
      id: 'weekly_set_reminders',
      label: 'Set reminders',
      icon: Icons.alarm,
      isComplete: (app) =>
          app.didEventWithin('reminders_set', const Duration(days: 7)),
    ),
    _AutoTask(
      id: 'weekly_review_categories',
      label: 'Review categories',
      icon: Icons.category,
      isComplete: (app) =>
          app.didEventWithin('categories_reviewed', const Duration(days: 7)),
    ),
    _AutoTask(
      id: 'weekly_save_receipt',
      label: 'Save receipt',
      icon: Icons.save,
      isComplete: (app) =>
          app.didEventWithin('receipt_saved', const Duration(days: 7)),
    ),
  ],
  'monthly': [
    _AutoTask(
      id: 'monthly_set_budgets',
      label: 'Set budgets',
      icon: Icons.calculate,
      isComplete: (app) =>
          app.didEventWithin('budget_updated', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_review_trends',
      label: 'Review trends',
      icon: Icons.leaderboard,
      isComplete: (app) =>
          app.didEventWithin('insights_viewed', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_pay_bills',
      label: 'Pay bills',
      icon: Icons.payments_outlined,
      isComplete: (app) =>
          app.didEventWithin('subscriptions_viewed', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_check_savings',
      label: 'Check savings',
      icon: Icons.savings,
      isComplete: (app) =>
          app.didEventWithin('goals_updated', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_audit_expenses',
      label: 'Audit expenses',
      icon: Icons.checklist,
      isComplete: (app) =>
          app.didEventWithin('transactions_viewed', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_update_targets',
      label: 'Update targets',
      icon: Icons.center_focus_strong,
      isComplete: (app) =>
          app.didEventWithin('goals_updated', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_review_subscriptions',
      label: 'Review subscriptions',
      icon: Icons.manage_accounts,
      isComplete: (app) =>
          app.didEventWithin('subscriptions_viewed', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_plan_next',
      label: 'Plan next month',
      icon: Icons.calendar_today,
      isComplete: (app) =>
          app.didEventWithin('budget_updated', const Duration(days: 30)),
    ),
    _AutoTask(
      id: 'monthly_celebrate',
      label: 'Celebrate wins',
      icon: Icons.emoji_events,
      isComplete: (app) => app.rewardPoints >= 10 || app.puzzleComplete,
    ),
  ],
};

// alias so main.dart can use either name
typedef HomePage = HomeScreen;
String formatCurrency(num amount, {String symbol = '\$'}) {
  return '$symbol${amount.toStringAsFixed(2)}';
}