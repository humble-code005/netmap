/// ==========================================================================
/// Quality Indicator Widget — Animated circular meter for signal quality.
///
/// Displays a smooth, animated arc with a gradient color that transitions
/// from red (poor) → orange (fair) → green (excellent). The score number
/// animates when it changes. Used on the scanner screen to highlight
/// the best available network.
/// ==========================================================================
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wifi_network_model.dart';

class QualityIndicator extends StatefulWidget {
  final int score;
  final double size;

  const QualityIndicator({
    super.key,
    required this.score,
    this.size = 100,
  });

  @override
  State<QualityIndicator> createState() => _QualityIndicatorState();
}

class _QualityIndicatorState extends State<QualityIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(QualityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _oldScore = _animation.value;
      _animation = Tween<double>(
        begin: _oldScore,
        end: widget.score.toDouble(),
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
        final animatedScore = _animation.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ArcPainter(score: animatedScore),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    animatedScore.round().toString(),
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.bold,
                      color: _getColor(animatedScore),
                    ),
                  ),
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: widget.size * 0.11,
                      color: Colors.grey,
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

  Color _getColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.redAccent;
  }
}

/// Custom painter that draws a gradient arc representing the quality score.
class _ArcPainter extends CustomPainter {
  final double score;

  _ArcPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final strokeWidth = size.width * 0.08;

    // Draw background arc (full circle, semi-transparent)
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75, // Start at 7:30 position
      pi * 1.5,   // Sweep 270 degrees
      false,
      bgPaint,
    );

    // Draw the score arc with gradient
    final sweepAngle = (score / 100) * pi * 1.5;
    if (sweepAngle > 0) {
      final gradient = SweepGradient(
        startAngle: -pi * 0.75,
        endAngle: -pi * 0.75 + pi * 1.5,
        colors: [Colors.redAccent, Colors.orange, Colors.lightGreen, Colors.greenAccent],
        stops: const [0.0, 0.33, 0.66, 1.0],
      );

      final scorePaint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi * 0.75,
        sweepAngle,
        false,
        scorePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.score != score;
}

/// Small icon widget showing WiFi signal strength with color coding.
class QualityIcon extends StatelessWidget {
  final SignalQuality quality;
  final double size;

  const QualityIcon({
    super.key,
    required this.quality,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (quality) {
      case SignalQuality.excellent:
        icon = Icons.signal_wifi_4_bar;
        color = Colors.greenAccent;
        break;
      case SignalQuality.good:
        icon = Icons.network_wifi_3_bar;
        color = Colors.lightGreen;
        break;
      case SignalQuality.fair:
        icon = Icons.network_wifi_2_bar;
        color = Colors.orange;
        break;
      case SignalQuality.poor:
        icon = Icons.network_wifi_1_bar;
        color = Colors.redAccent;
        break;
    }

    return Icon(icon, color: color, size: size);
  }
}
