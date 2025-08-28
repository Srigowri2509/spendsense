// ignore_for_file: prefer_const_constructors
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with TickerProviderStateMixin {
  late AnimationController confetti;

  @override
  void initState() {
    super.initState();
    confetti = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    confetti.dispose();
    super.dispose();
  }

  bool _isBingo(List<bool> filled) {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final L in lines) {
      if (filled[L[0]] && filled[L[1]] && filled[L[2]]) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    // Take up to 9 tasks; pad if fewer
    final tasks = List<UnlockTask>.from(app.unlockTasks);
    while (tasks.length < 9) {
      tasks.add(UnlockTask(
        type: UnlockTaskType.addExpense,
        title: 'Bonus',
        hint: 'Any small action',
        done: false,
      ));
    }
    final filled = List<bool>.generate(9, (i) => i < tasks.length ? tasks[i].done : false);

    return Scaffold(
      appBar: AppBar(title: const Text('Bingo')),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 340,
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
                ),
                itemBuilder: (_, i) {
                  final t = tasks[i];
                  final done = t.done;
                  return GestureDetector(
                    onTap: () async {
                      // Show task + allow marking done (demo)
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(t.title),
                          content: Text(t.hint),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark done')),
                          ],
                        ),
                      );
                      if (ok == true && !t.done) {
                        setState(() => t.done = true);
                        // reward & confetti on bingo
                        if (_isBingo(List<bool>.generate(9, (k) => tasks[k].done))) {
                          app.incrementPuzzleCompleted();
                          app.rewardPoints += 20;
                          confetti
                            ..reset()
                            ..forward();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bingo! +20 points')),
                          );
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: done
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(done ? Icons.check_circle : Icons.flag_outlined,
                              color: done
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 6),
                          Text(
                            t.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: done ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // confetti burst
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: confetti,
                builder: (_, __) => CustomPaint(painter: _ConfettiPainter(confetti.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t; // 0..1
  final math.Random _rng = math.Random();
  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0) return;
    final center = size.center(Offset.zero);
    final count = 120;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final speed = 60 + 140 * (_rng.nextDouble());
      final dx = math.cos(angle) * speed * t * (1.0 + .4 * _rng.nextDouble());
      final dy = math.sin(angle) * speed * t * (1.0 + .4 * _rng.nextDouble());
      final p = Paint()
        ..color = HSLColor.fromAHSL(1, (i * 13) % 360.0, .7, .6).toColor()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, center + Offset(dx, dy), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
