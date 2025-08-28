// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import '../app_state.dart';

class ScoreboardPage extends StatelessWidget {
  const ScoreboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // Demo peers + the user; sort by completed desc
    final players = <_Player>[
      _Player('Aarav', 7),
      _Player('Meera', 6),
      _Player('Sid', 5),
      _Player('You', app.puzzlesCompleted),
    ]..sort((a, b) => b.completed.compareTo(a.completed));

    // Top 3 for podium, rest below
    final podium = players.take(3).toList();
    final rest = players.length > 3 ? players.sublist(3) : <_Player>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Scoreboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _MetricPill(
            icon: Icons.grid_4x4,
            label: 'Bingo / Puzzles completed',
            value: app.puzzlesCompleted.toString(),
          ),
          const SizedBox(height: 12),
          _MetricPill(
            icon: Icons.stars_rounded,
            label: 'Reward points',
            value: app.rewardPoints.toString(),
          ),
          const SizedBox(height: 16),

          Text('Top finishers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          _PodiumRow(players: podium),

          if (rest.isNotEmpty) const SizedBox(height: 16),
          if (rest.isNotEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  for (final p in rest) ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(p.name),
                    trailing: Text('${p.completed}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricPill({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PodiumRow extends StatelessWidget {
  final List<_Player> players; // top 3 (already sorted)
  const _PodiumRow({required this.players});

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFFFD54F);
    final silver = const Color(0xFFB0BEC5);
    final bronze = const Color(0xFFB87333);

    // ensure 3 slots
    final p = List<_Player?>.from(players);
    while (p.length < 3) { p.add(null); }

    Widget _col(_Player? pl, int place, Color color, double h) {
      return Expanded(
        child: Column(
          children: [
            Text(
              place == 1 ? '1st' : place == 2 ? '2nd' : '3rd',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: h,
              decoration: BoxDecoration(
                color: color.withOpacity(.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: color),
                    const SizedBox(height: 4),
                    Text(pl?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(pl != null ? '${pl.completed}' : '—'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _col(p[1], 2, silver, 110),
        const SizedBox(width: 8),
        _col(p[0], 1, gold, 140),
        const SizedBox(width: 8),
        _col(p[2], 3, bronze, 95),
      ],
    );
  }
}

class _Player {
  final String name;
  final int completed;
  _Player(this.name, this.completed);
}
