// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import '../app_state.dart';
import 'expense_detail_screen.dart';

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({super.key});

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).markBingoEvent('spending_viewed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final tileW = (constraints.maxWidth - 16 - 16 - gap) / 2; // padding L/R + gap
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  'Spendings',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                // 2-up grid using Wrap (layout unchanged)
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final c in app.categories)
                      _NotebookTile(width: tileW, category: c),
                  ],
                ),

                const SizedBox(height: 16),
                _RemindersCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/* ─────────────── Notebook tile (2-up) ─────────────── */

class _NotebookTile extends StatelessWidget {
  final double width;
  final Category category;
  const _NotebookTile({required this.width, required this.category});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? cs.outline : Colors.black87;
    final headerColor = isDark ? cs.surfaceVariant.withOpacity(.7) : Colors.white;
    final headerTextColor = cs.onSurface;
    final tileColor = isDark ? _tint(category.color, .28) : _tint(category.color, .92);
    final pageColor = isDark ? _tint(category.color, .22) : _tint(category.color, .82);
    final accentColor = cs.onSurface;
    String money(num n) => formatCurrency(n, symbol: app.currencySymbol);

    // recent 3 for this category
    final tx = app.transactions
        .where((t) => t.category == category.type)
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    final recent = tx.take(3).map<_RowItem>((t) {
      return _RowItem(left: t.merchant, right: money(t.amount));
    }).toList();

    final total = app.spentFor(category.type);
    final title = switch (category.type) {
      CategoryType.rent => 'NECESSITIES',
      CategoryType.luxuries => 'LUX',
      _ => category.name.toUpperCase(),
    };

    const tileH = 290.0; // fixed ➜ no bottom overflow
    const ledgerRows = 6;

    final tile = Container(
      width: width,
      height: tileH,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Column(
        children: [
          // Title pill
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: headerTextColor,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // Ledger page fills the rest (fixed height inside tile)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: _LedgerPage(
                pageColor: pageColor,
                borderColor: borderColor,
                textColor: accentColor.withOpacity(.9),
                accentColor: accentColor,
                rows: _padRows(recent, ledgerRows),
                totalText: money(total),
                rowCount: ledgerRows,
              ),
            ),
          ),
        ],
      ),
    );

    // Make it tappable → push full detail
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _CategoryDetailPage(category: category)),
          );
        },
        child: tile,
      ),
    );
  }

  static List<_RowItem> _padRows(List<_RowItem> src, int want) {
    final out = <_RowItem>[];
    out.addAll(src);
    while (out.length < want) {
      out.add(const _RowItem(left: '', right: ''));
    }
    return out.take(want).toList();
  }
}

/* ─────────────── Ledger page (lines + TOTAL) ─────────────── */

class _LedgerPage extends StatelessWidget {
  final Color pageColor;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final List<_RowItem> rows; // must be rowCount length
  final int rowCount;
  final String totalText;
  const _LedgerPage({
    required this.pageColor,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    required this.rows,
    required this.totalText,
    required this.rowCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pageColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          // Lines
          for (final r in rows)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderColor, width: 1.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor, fontSize: 13),
                      ),
                    ),
                    Text(
                      r.right,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Thick separator
          Container(
            height: 18,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 2),
              ),
            ),
          ),

          // TOTAL line (aligned right)
          Row(
            children: [
              Text('TOTAL:',
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.w800)),
              const Spacer(),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              totalText,
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────── Category Detail Page ─────────────── */

class _CategoryDetailPage extends StatelessWidget {
  final Category category;
  const _CategoryDetailPage({required this.category});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? cs.outline : Colors.black87;
    final headerColor = isDark ? cs.surfaceVariant.withOpacity(.7) : Colors.white;
    final headerTextColor = cs.onSurface;
    final tileColor = isDark ? _tint(category.color, .24) : _tint(category.color, .86);
    final textColor = cs.onSurface;
    final accentColor = cs.onSurface;
    String money(num n) => formatCurrency(n, symbol: app.currencySymbol);

    final title = switch (category.type) {
      CategoryType.rent => 'NECESSITIES',
      CategoryType.luxuries => 'LUXURIES',
      _ => category.name.toUpperCase(),
    };

    final tx = app.transactions
        .where((t) => t.category == category.type)
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));

    final total = app.spentFor(category.type);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.4),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: headerTextColor,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.4),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: tx.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 0,
                        thickness: 1.2,
                        color: borderColor.withOpacity(.3),
                      ),
                      itemBuilder: (_, i) {
                        final t = tx[i];
                        final date =
                            '${t.time.day.toString().padLeft(2, '0')}/${t.time.month.toString().padLeft(2, '0')}';
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ExpenseDetailScreen(transaction: t),
                              ),
                            );
                          },
                          child: SizedBox(
                            height: 36,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${t.merchant}  •  $date',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                Text(
                                  money(t.amount),
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    height: 18,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: borderColor, width: 2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Text(
                          'TOTAL:',
                          style: TextStyle(
                              color: accentColor, fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Text(
                          money(total),
                          style: TextStyle(
                              color: accentColor, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────── Reminders panel ─────────────── */

class _RemindersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    final progress = now.day / days;

    final items = <String>[];

    for (final c in app.categories) {
      final spent = app.spentFor(c.type);
      if (c.monthlyBudget <= 0) continue;
      final expected = c.monthlyBudget * progress;
      final diff = spent - expected;
      final pct = expected == 0 ? 0 : (diff / expected) * 100;

      if (pct >= 20) {
        items.add('You have spent ${pct.round()}% more on ${_label(c)} than expected.');
      } else if (pct <= -20) {
        items.add('You have saved ${pct.abs().round()}% on ${_label(c)} so far. Hurray!');
      }
      if (items.length >= 3) break;
    }

    final dueSoon = [...app.subscriptions]..sort((a, b) {
        final ad = _nextDue(a.billingDay);
        final bd = _nextDue(b.billingDay);
        return ad.compareTo(bd);
      });
    for (final s in dueSoon.take(2)) {
      final d = _nextDue(s.billingDay);
      items.add('${s.name} due on ${d.day}/${d.month}.');
    }

    if (items.isEmpty) items.add('All good! You’re on track this month.');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reminders (based on your habits)',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...items.map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_none_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(Category c) =>
      c.type == CategoryType.rent ? 'necessities' : c.name.toLowerCase();

  static DateTime _nextDue(int day) {
    final now = DateTime.now();
    final days = DateUtils.getDaysInMonth(now.year, now.month);
    final d = day.clamp(1, days);
    final cand = DateTime(now.year, now.month, d);
    if (cand.isBefore(DateTime(now.year, now.month, now.day))) {
      final ny = now.month == 12 ? now.year + 1 : now.year;
      final nm = now.month == 12 ? 1 : now.month + 1;
      final ndays = DateUtils.getDaysInMonth(ny, nm);
      final nd = day.clamp(1, ndays);
      return DateTime(ny, nm, nd);
    }
    return cand;
  }
}

/* ─────────────── Helpers ─────────────── */

class _RowItem {
  final String left;
  final String right;
  const _RowItem({required this.left, required this.right});
}

Color _tint(Color base, double lightness) {
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
}
