import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

/// Small pieces of motion shared by the offers screen, the checkout
/// control and the scratch rewards. Each one stands still when the device
/// asks for reduced motion.

/// Lets a row arrive: a short rise and fade, later rows a beat behind.
class Entrance extends StatefulWidget {
  final int index;
  final Widget child;
  const Entrance({super.key, required this.index, required this.child});
  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const _rise = 380;
  static const _beat = 65;
  late final int _wait = widget.index.clamp(0, 7) * _beat;
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _wait + _rise),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arrive = CurvedAnimation(
      parent: _controller,
      curve: Interval(_wait / (_wait + _rise), 1, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: arrive,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: arrive.value,
        child: Transform.translate(
          offset: Offset(0, (1 - arrive.value) * 22),
          child: child,
        ),
      ),
    );
  }
}

/// A quick side-to-side "no" that dies away, for a code that did not work.
class Shake extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const Shake({super.key, required this.animation, required this.child});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final t = animation.value;
      return Transform.translate(
        offset: Offset(math.sin(t * math.pi * 5) * 9 * (1 - t), 0),
        child: child,
      );
    },
  );
}

/// Bits of paper thrown up from one point, falling back under their own
/// weight. Driven from 0 to 1; draws nothing at either end.
class PaperBurstPainter extends CustomPainter {
  final double t;
  final Alignment origin;
  final int seed;
  final int pieces;
  final double reach;
  const PaperBurstPainter({
    required this.t,
    this.origin = Alignment.center,
    this.seed = 7,
    this.pieces = 22,
    this.reach = 1,
  });

  static const _paper = [
    AppColors.brandPrimary,
    Color(0xffdce9b3),
    Color(0xfff3e9c6),
    Color(0xffe0a43a),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final random = math.Random(seed);
    final from = origin.alongSize(size);
    final thrown = Curves.easeOutCubic.transform(t);
    final fade = t < .6 ? 1.0 : 1 - (t - .6) / .4;
    for (var i = 0; i < pieces; i++) {
      // Mostly upwards, fanned out to both sides.
      final angle = -math.pi / 2 + (random.nextDouble() - .5) * math.pi * 1.3;
      final speed = (90 + random.nextDouble() * 170) * reach;
      final width = 4 + random.nextDouble() * 5;
      final spin = (random.nextDouble() - .5) * 10;
      final turn = random.nextDouble() * math.pi;
      final colour = _paper[random.nextInt(_paper.length)];
      final at =
          from +
          Offset(
            math.cos(angle) * speed * thrown,
            math.sin(angle) * speed * thrown + 260 * reach * t * t,
          );
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(turn + spin * t)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: width * .6,
            ),
            const Radius.circular(1),
          ),
          Paint()..color = colour.withValues(alpha: fade),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(PaperBurstPainter old) =>
      old.t != t || old.origin != origin || old.seed != seed;
}
