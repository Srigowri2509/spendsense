// lib/widgets/gauge.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class Gauge extends StatelessWidget {
  /// value in the range 0..1
  final double value;
  const Gauge({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 90),
      painter: _GaugePainter(value.clamp(0.0, 1.0)),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..1
  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    // Background arc (half circle)
    final bg = Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, math.pi, math.pi, false, bg);

    // Colored sweep
    final seg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: math.pi,
        endAngle: math.pi * (1 + value),
        colors: [
          Colors.greenAccent.withOpacity(.9),
          Colors.amberAccent.withOpacity(.9),
          Colors.orangeAccent.withOpacity(.9),
          Colors.redAccent.withOpacity(.9),
        ],
        stops: const [0.0, 0.33, 0.66, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, math.pi, math.pi * value, false, seg);

    // Needle
    final angle = math.pi * (1 + value);
    final tip = center + Offset(
      radius * -math.cos(angle),
      radius * -math.sin(angle),
    );

    final needle = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    canvas.drawLine(center, tip, needle);
    canvas.drawCircle(center, 4, needle);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    // repaint only if the value changed
    return oldDelegate.value != value;
  }
}
