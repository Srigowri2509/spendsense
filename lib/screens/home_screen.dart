import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets/donut_chart.dart';
import '../widgets/gauge.dart';
import 'puzzle_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final donutData = <Color, double>{};
    for (final c in state.categories) {
      donutData[c.color] = state.spentFor(c.type);
    }

    final luxCat = state.categories.firstWhere((c) => c.type == CategoryType.luxuries);
    final double luxSpent = state.spentFor(CategoryType.luxuries);
    final double luxBudget = luxCat.monthlyBudget == 0 ? 1 : luxCat.monthlyBudget;
    final double luxValue = (luxSpent / luxBudget).clamp(0.0, 1.0).toDouble();

    final double emergencyPct = (state.emergencySaved / (state.emergencyTarget == 0 ? 1 : state.emergencyTarget))
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      // subtle gradient to make the tinted bg feel premium
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: .94),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(title: Text('Home'), floating: true),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    // ---------- Monthly Spending ----------
                    _CardBlock(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _TitleText('Monthly Spending'),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              DonutChart(
                                data: donutData,
                                size: 156,
                                centerLabel: formatCurrency(state.totalSpentThisMonth, symbol: state.currencySymbol),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: state.categories
                                      .map((c) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: _LegendRow(
                                              color: c.color,
                                              label: c.name,
                                              amount: formatCurrency(state.spentFor(c.type), symbol: state.currencySymbol),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ---------- Wallets (PhonePe-style) ----------
                    _SectionHeader('Wallets'),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        itemBuilder: (_, i) {
                          final w = state.wallets[i];
                          return _WalletCard(
                            icon: w.icon,
                            title: w.name,
                            amount: formatCurrency(w.balance, symbol: state.currencySymbol),
                            color: w.color,
                            onAdd: () => _showAddToWallet(context, state, w.id),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: state.wallets.length,
                      ),
                    ),

                    // ---------- Emergency + Luxuries ----------
                    Row(
                      children: [
                        Expanded(
                          child: _CardBlock(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _TitleText('Emergency Fund'),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(value: emergencyPct, minHeight: 10),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('${(emergencyPct * 100).toStringAsFixed(0)}%'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Saved'),
                                    Text(formatCurrency(state.emergencySaved, symbol: state.currencySymbol)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CardBlock(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _TitleText('Luxuries'),
                                const SizedBox(height: 6),
                                Center(child: Gauge(value: luxValue)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(formatCurrency(luxSpent, symbol: state.currencySymbol)),
                                    Text('of ${formatCurrency(luxBudget, symbol: state.currencySymbol)}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ---------- Quick actions ----------
                    _SectionHeader('Quick Actions'),
                    _CardBlock(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ActionChip(icon: Icons.add, label: 'Expense', onTap: () {
                            // route to your Add screen if you want
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Add expense')));
                          }),
                          _ActionChip(icon: Icons.account_balance, label: 'Link bank', onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Linked banks')));
                          }),
                          _ActionChip(icon: Icons.attach_money, label: 'Salary credit', onTap: () {
                            _showSalarySheet(context, state);
                          }),
                        ],
                      ),
                    ),

                    // ---------- Puzzle ----------
                    _CardBlock(
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.extension, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Complete to unlock', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.tasksDone}/${state.unlockTasks.length} tasks done • ${state.unlockedCount}/${state.totalPieces} pieces unlocked',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          FilledButton(onPressed: () => Navigator.pushNamed(context, PuzzleScreen.route), child: const Text('Open')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToWallet(BuildContext context, AppState state, String id) {
    final amt = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to wallet'),
        content: TextField(controller: amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(amt.text.trim());
              if (v == null || v <= 0) return;
              state.depositToWallet(id, v);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSalarySheet(BuildContext context, AppState state) {
    final c = TextEditingController();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Credit salary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)')),
            const SizedBox(height: 12),
            Text('Auto-save ${state.autoSavePercent.toStringAsFixed(0)}% → Savings wallet', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(c.text.trim());
                if (v == null || v <= 0) return;
                state.creditSalary(v);
                Navigator.pop(context);
              },
              child: const Text('Credit'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- helpers ----------
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final Widget child;
  const _CardBlock({required this.child});
  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: .18);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: tint, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _TitleText extends StatelessWidget {
  final String text;
  const _TitleText(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  const _LegendRow({required this.color, required this.label, required this.amount});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(amount),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final Color color;
  final VoidCallback onAdd;
  const _WalletCard({required this.icon, required this.title, required this.amount, required this.color, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 4)),
      ]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: .15), child: Icon(icon, color: color)),
            const Spacer(),
            IconButton(onPressed: onAdd, icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(amount, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Row(children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
