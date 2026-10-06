import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/sound_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

import '../../../../l10n/generated/app_localizations.dart';

/// The original brand layers, brought to life as a small tactile keepsake.
/// The mark draws itself in, a bell lands with the dot, and every tap after
/// that plays the next note of a short scale.
class KayloSecret extends ConsumerStatefulWidget {
  const KayloSecret({super.key});
  @override
  ConsumerState<KayloSecret> createState() => _KayloSecretState();
}

class _KayloSecretState extends ConsumerState<KayloSecret>
    with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final _touch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  /// Up the scale and back down, so idle tapping turns into a little tune.
  static const _tune = [0, 1, 2, 3, 4, 3, 2, 1];

  /// Where in the intro the dot starts to land; the bell rings with it.
  static const _dotLands = .45;
  Offset _lean = Offset.zero;
  bool _started = false;
  bool _rung = false;
  int _taps = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Reduced motion skips the drawing-in, not the welcome.
      _intro.value = 1;
      _touch.value = 1;
      _ring();
    } else {
      _intro.addListener(_ringWhenDotLands);
      _intro.forward();
    }
  }

  void _ringWhenDotLands() {
    if (_intro.value >= _dotLands) _ring();
  }

  void _ring() {
    if (_rung) return;
    _rung = true;
    KayloFeedback.soft();
    ref.read(soundServiceProvider).play(KayloSound.logoChime);
  }

  @override
  void dispose() {
    _intro.dispose();
    _touch.dispose();
    super.dispose();
  }

  void _play() {
    KayloFeedback.soft();
    final note = KayloSound.notes[_tune[_taps++ % _tune.length]];
    ref.read(soundServiceProvider).play(note);
    if (!MediaQuery.disableAnimationsOf(context)) _touch.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                label: l10n.secretSemantics,
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
                            _dotLands,
                            .8,
                            curve: Curves.easeOutBack,
                          ).transform(_intro.value);
                          final word = const Interval(
                            .65,
                            1,
                            curve: Curves.easeOutCubic,
                          ).transform(_intro.value);
                          // The ring the bell sends out as the dot lands.
                          final landing = const Interval(
                            _dotLands,
                            1,
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
                                    painter: _Ripples(
                                      touch: _touch.value,
                                      landing: landing,
                                      color: ink,
                                    ),
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
                                left: 0,
                                right: 0,
                                child: Opacity(
                                  opacity: word,
                                  child: Text(
                                    l10n.secretTagline,
                                    textAlign: TextAlign.center,
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

/// Sound made visible: a ring spreading from the mark when the bell rings
/// and on every tap, with a scatter of seeds on a tap.
class _Ripples extends CustomPainter {
  final double touch;
  final double landing;
  final Color color;
  _Ripples({required this.touch, required this.landing, required this.color});

  void _ring(Canvas canvas, Offset center, double t, double reach) {
    if (t <= 0 || t >= 1) return;
    final eased = Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
      center,
      70 + reach * eased,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1 - t) + .4
        ..color = color.withValues(alpha: (1 - t) * .38),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    _ring(canvas, center, landing, 150);
    _ring(canvas, center, touch, 120);
    // A second, slower ring trails the first, the way a struck bell hums.
    _ring(canvas, center, (touch - .12) / .88, 80);
    if (touch == 0 || touch == 1) return;
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final radius = 95 + 90 * Curves.easeOutCubic.transform(touch);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(
        point,
        2.5 * (1 - touch),
        Paint()..color = color.withValues(alpha: (1 - touch) * .6),
      );
    }
  }

  @override
  bool shouldRepaint(_Ripples old) =>
      old.touch != touch || old.landing != landing || old.color != color;
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
