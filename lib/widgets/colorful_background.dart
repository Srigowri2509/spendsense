import 'package:flutter/material.dart';

class ColorfulBackground extends StatelessWidget {
  final Widget child;
  final Alignment begin;
  final Alignment end;
  final List<Color>? colors;
  final double opacity;

  const ColorfulBackground({
    super.key,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.colors,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final baseColors = colors ??
        [
          isDark
              ? cs.primaryContainer.withOpacity(.35)
              : cs.primaryContainer.withOpacity(.75 * opacity),
          isDark
              ? cs.secondaryContainer.withOpacity(.35)
              : cs.secondaryContainer.withOpacity(.65 * opacity),
          isDark
              ? cs.surface.withOpacity(.6)
              : cs.tertiaryContainer.withOpacity(.55 * opacity),
        ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: baseColors,
        ),
      ),
      child: child,
    );
  }
}

