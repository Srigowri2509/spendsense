// lib/widgets/donut_chart.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class DonutChart extends StatelessWidget {
  final Map<Color, double> data; // color -> value
  final double size;
  final String centerLabel;
  const DonutChart({
    super.key,
    required this.data,
    this.size = 160,
    this.centerLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(data: data),
        child: Center(
          child: Text(
            centerLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<Color, double> data;
  _DonutPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    final stroke = radius * 0.28;

    final total = data.values.fold<double>(0.0, (a, b) => a + b);
    double start = -90 * (math.pi / 180.0); // start at top

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    if (total <= 0) {
      // draw a faint ring when there is no data
      paint
        .color = const Color(0xFF9E9E9E).withValues(alpha: 0.18);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        2 * math.pi,
        false,
        paint,
      );
      // inner soft center
      final inner = Paint()..color = Colors.white.withValues(alpha: 0.04);
      canvas.drawCircle(center, radius - stroke, inner);
      return;
    }

    for (final entry in data.entries) {
      final value = entry.value;
      if (value <= 0) continue; // skip empty slices

      final sweep = (value / total) * 2 * math.pi;
      paint.color = entry.key.withValues(alpha: 0.95);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }

    // subtle inner circle to complete the donut
    final inner = Paint()..color = Colors.white.withValues(alpha: 0.04);
    canvas.drawCircle(center, radius - stroke, inner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
