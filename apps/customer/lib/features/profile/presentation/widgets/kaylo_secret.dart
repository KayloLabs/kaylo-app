import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

/// The original brand layers, brought to life as a small tactile keepsake.
class KayloSecret extends StatefulWidget {
  const KayloSecret({super.key});
  @override
  State<KayloSecret> createState() => _KayloSecretState();
}

class _KayloSecretState extends State<KayloSecret>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final _touch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  Offset _lean = Offset.zero;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
      _touch.value = 1;
    } else if (!_started) {
      _intro.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _intro.dispose();
    _touch.dispose();
    super.dispose();
  }

  void _play() {
    KayloFeedback.press();
    if (!MediaQuery.disableAnimationsOf(context)) _touch.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final ink = dark ? const Color(0xFFA9DEC0) : AppColors.brandPrimary;
    return Dialog.fullscreen(
      backgroundColor: dark ? const Color(0xFF101F18) : const Color(0xFFF3F6EF),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              right: 16,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Center(
              child: Semantics(
                label: 'Kaylo. Made with care.',
                button: true,
                child: GestureDetector(
                  onTap: _play,
                  onPanUpdate: (d) {
                    if (!reduce) {
                      setState(
                        () => _lean = Offset(
                          (_lean.dx + d.delta.dx * .3).clamp(-18, 18),
                          (_lean.dy + d.delta.dy * .3).clamp(-18, 18),
                        ),
                      );
                    }
                  },
                  onPanEnd: (_) {
                    setState(() => _lean = Offset.zero);
                    _play();
                  },
                  onPanCancel: () => setState(() => _lean = Offset.zero),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(_lean.dx, _lean.dy, 0),
                    child: SizedBox(
                      width: math.min(
                        MediaQuery.sizeOf(context).width - 40,
                        400,
                      ),
                      height: 420,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_intro, _touch]),
                        builder: (context, _) {
                          final reveal = const Interval(
                            0,
                            .65,
                            curve: Curves.easeInOutCubic,
                          ).transform(_intro.value);
                          final dot = const Interval(
                            .45,
                            .8,
                            curve: Curves.easeOutBack,
                          ).transform(_intro.value);
                          final word = const Interval(
                            .65,
                            1,
                            curve: Curves.easeOutCubic,
                          ).transform(_intro.value);
                          final bounce =
                              math.sin(_touch.value * math.pi * 2) *
                              math.exp(-4 * _touch.value);
                          Widget layer(String name) => SvgPicture.asset(
                            'assets_kaylo/logo_$name.svg',
                            colorFilter: ColorFilter.mode(ink, BlendMode.srcIn),
                          );
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!reduce)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _Ripples(_touch.value, ink),
                                  ),
                                ),
                              Transform.translate(
                                offset: Offset(0, -bounce * 18),
                                child: SizedBox(
                                  width: 310,
                                  height: 310,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRect(
                                        clipper: _LogoReveal(reveal),
                                        child: layer('loop'),
                                      ),
                                      Transform.scale(
                                        scale: math.max(
                                          .001,
                                          dot + bounce * .14,
                                        ),
                                        child: layer('dot'),
                                      ),
                                      Opacity(
                                        opacity: word,
                                        child: Transform.translate(
                                          offset: Offset(0, (1 - word) * 12),
                                          child: layer('text'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 28,
                                child: Opacity(
                                  opacity: word,
                                  child: Text(
                                    'A little care goes a long way.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: ink),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ripples extends CustomPainter {
  final double t;
  final Color color;
  _Ripples(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    final center = size.center(Offset.zero);
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final radius = 95 + 90 * Curves.easeOutCubic.transform(t);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        2.5 * (1 - t),
        Paint()..color = color.withValues(alpha: (1 - t) * .6),
      );
    }
  }

  @override
  bool shouldRepaint(_Ripples old) => old.t != t || old.color != color;
}

class _LogoReveal extends CustomClipper<Rect> {
  final double progress;
  const _LogoReveal(this.progress);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);
  @override
  bool shouldReclip(_LogoReveal old) => old.progress != progress;
}
