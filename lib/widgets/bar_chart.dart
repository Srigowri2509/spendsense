import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A tiny, dependency-free bar chart used in Insights.
/// Now supports per-bar colors.
class SimpleBarChart extends StatelessWidget {
  final List<double> values;     // e.g., monthly totals or categories
  final List<String> labels;     // same length as values
  final List<Color>? barColors;  // optional per-bar colors
  final double height;

  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColors,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    assert(values.length == labels.length, 'values and labels must have same length');
    final maxV = values.isEmpty ? 1.0 : values.reduce(math.max).clamp(1.0, double.infinity);
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, c) {
        final barW = values.isEmpty ? 0.0 : (c.maxWidth / values.length) * 0.5;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(values.length, (i) {
            final v = values[i];
            final h = (v / maxV) * (height - 40); // leave some space for labels
            final base = (barColors != null && i < barColors!.length)
                ? barColors![i]
                : cs.primary;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: v.toStringAsFixed(0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: h,
                    width: barW,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          base.withValues(alpha: .85),
                          base.withValues(alpha: .55),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[i], style: Theme.of(context).textTheme.labelSmall),
              ],
            );
          }),
        );
      }),
    );
  }
}
