import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final String leftLabel;
  final String rightLabel;
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.leftLabel = '',
    this.rightLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: LayoutBuilder(builder: (context, c) {
            return Stack(
              children: [
                Container(height: height, color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: height,
                  width: c.maxWidth * value.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ]),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(leftLabel), Text(rightLabel)],
        ),
      ],
    );
  }
}
