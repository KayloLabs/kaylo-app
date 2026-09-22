import 'dart:math';
import 'package:flutter/material.dart';

class GooglePayTick extends StatefulWidget {
  final double size;
  final Color color;

  const GooglePayTick({super.key, this.size = 104, this.color = Colors.green});

  @override
  State<GooglePayTick> createState() => _GooglePayTickState();
}

class _GooglePayTickState extends State<GooglePayTick>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _tickAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _tickAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation =
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _TickPainter(
              color: widget.color,
              circleProgress: _circleAnimation.value,
              tickProgress: _tickAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

class _TickPainter extends CustomPainter {
  final Color color;
  final double circleProgress;
  final double tickProgress;

  _TickPainter({
    required this.color,
    required this.circleProgress,
    required this.tickProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - paint.strokeWidth / 2;

    // Background circle (faint)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Animated circle outline
    if (circleProgress > 0.0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * circleProgress,
        false,
        paint,
      );
    }

    // Animated checkmark
    if (tickProgress > 0.0) {
      final path = Path();
      // Tick starting point
      final start = Offset(size.width * 0.25, size.height * 0.5);
      // Tick bottom point
      final mid = Offset(size.width * 0.45, size.height * 0.7);
      // Tick end point
      final end = Offset(size.width * 0.75, size.height * 0.35);

      path.moveTo(start.dx, start.dy);

      if (tickProgress < 0.5) {
        // Draw to mid
        final p = tickProgress * 2;
        path.lineTo(
          start.dx + (mid.dx - start.dx) * p,
          start.dy + (mid.dy - start.dy) * p,
        );
      } else {
        // Draw to end
        path.lineTo(mid.dx, mid.dy);
        final p = (tickProgress - 0.5) * 2;
        path.lineTo(
          mid.dx + (end.dx - mid.dx) * p,
          mid.dy + (end.dy - mid.dy) * p,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TickPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.tickProgress != tickProgress ||
        oldDelegate.color != color;
  }
}
