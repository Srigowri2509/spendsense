import 'package:flutter/material.dart';
import 'dart:math' as math;

class SimpleBarChart extends StatelessWidget {
  final List<double> values;     // e.g., monthly totals
  final List<String> labels;     // e.g., Jan..Dec
  final double height;
  const SimpleBarChart({super.key, required this.values, required this.labels, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1.0 : values.reduce(math.max);
    return SizedBox(
      height: height,
      child: LayoutBuilder(builder: (context, c) {
        final barW = (c.maxWidth / values.length) * 0.5;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < values.length; i++) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      height: maxV == 0 ? 2 : (values[i] / maxV) * (height - 36),
                      width: barW,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: .85),
                            Theme.of(context).colorScheme.primary.withValues(alpha: .55),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(labels[i], style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}
