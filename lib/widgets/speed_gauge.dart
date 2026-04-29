/// ==========================================================================
/// Speed Gauge Widget — Animated speedometer for speed test results.
///
/// A custom-painted circular gauge that fills up during the speed test,
/// showing the current measurement with smooth animation.
/// ==========================================================================
import 'dart:math';
import 'package:flutter/material.dart';

class SpeedGauge extends StatefulWidget {
  final double value; // Current speed in Mbps
  final double maxValue; // Maximum scale value
  final String label; // e.g., "Download", "Upload"
  final String unit; // e.g., "Mbps"
  final Color color;

  const SpeedGauge({
    super.key,
    required this.value,
    this.maxValue = 100,
    this.label = '',
    this.unit = 'Mbps',
    this.color = Colors.cyanAccent,
  });

  @override
  State<SpeedGauge> createState() => _SpeedGaugeState();
}

class _SpeedGaugeState extends State<SpeedGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(SpeedGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 180),
          painter: _GaugePainter(
            value: _animation.value,
            maxValue: widget.maxValue,
            color: widget.color,
          ),
          child: SizedBox(
            width: 180,
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _animation.value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                  Text(
                    widget.unit,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (widget.label.isNotEmpty)
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.color.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  _GaugePainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    final strokeWidth = 10.0;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    // Value arc
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    final sweepAngle = ratio * pi * 1.5;

    if (sweepAngle > 0) {
      final valuePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi * 0.75,
        sweepAngle,
        false,
        valuePaint,
      );
    }

    // Draw tick marks
    for (int i = 0; i <= 10; i++) {
      final angle = -pi * 0.75 + (i / 10) * pi * 1.5;
      final outerPoint = Offset(
        center.dx + (radius + 8) * cos(angle),
        center.dy + (radius + 8) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 4) * cos(angle),
        center.dy + (radius - 4) * sin(angle),
      );

      final tickPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = i % 5 == 0 ? 2 : 1;

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}
