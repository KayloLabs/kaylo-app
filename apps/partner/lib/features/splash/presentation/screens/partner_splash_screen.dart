import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

import '../../../../core/router/routes.dart';
import '../../../auth/application/partner_session.dart';

/// The first thing a worker sees: the Kaylo mark draws itself onto a deep
/// green field, the dot lands, the wordmark rises, and "PARTNER" settles
/// beneath it while a hairline fills. The session is checked meanwhile,
/// and the screen leaves for Jobs or sign-in the moment both are done.
/// Reduced motion shows the finished mark briefly instead.
class PartnerSplashScreen extends ConsumerStatefulWidget {
  const PartnerSplashScreen({super.key});

  @override
  ConsumerState<PartnerSplashScreen> createState() =>
      _PartnerSplashScreenState();
}

class _PartnerSplashScreenState extends ConsumerState<PartnerSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  late final Animation<double> _loop = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.50, curve: Curves.easeInOut),
  );
  late final Animation<double> _dot = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.50, 0.62, curve: Curves.easeOutBack),
  );
  late final Animation<double> _word = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.60, 0.76, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _badge = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.74, 0.88, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.80, 0.98, curve: Curves.easeInOut),
  );
  late final Animation<double> _bar = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.30, 1.0, curve: Curves.easeInOutCubic),
  );

  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final session = ref.read(partnerAuthRepositoryProvider).isAuthenticated();
    bool signedIn;
    if (reduceMotion) {
      _controller.value = 1.0;
      signedIn = await session;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } else {
      _ambient.repeat();
      final results = await Future.wait<Object?>([
        session,
        _controller.forward(),
      ]);
      signedIn = results.first as bool;
      if (!mounted) return;
      setState(() => _exiting = true);
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted) return;
    context.go(signedIn ? Routes.jobs : Routes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Colors.white;
    return Scaffold(
      backgroundColor: AppColors.brandPrimaryDark,
      body: AnimatedOpacity(
        opacity: _exiting ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The field: deep green, darker towards the bottom.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.brandPrimaryDark, Color(0xFF0E2418)],
                ),
              ),
            ),
            // Two slow lights drifting behind the mark.
            AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) =>
                  CustomPaint(painter: _AmbientLights(_ambient.value)),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Kaylo Partner',
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => _Sweep(
                          progress: _sweep.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRect(
                                clipper: _Reveal(_loop.value),
                                child: const _Mark(
                                  'assets_kaylo/logo_loop.svg',
                                  ink,
                                ),
                              ),
                              Transform.scale(
                                scale: _dot.value,
                                child: Opacity(
                                  opacity: _dot.value.clamp(0.0, 1.0),
                                  child: const _Mark(
                                    'assets_kaylo/logo_dot.svg',
                                    AppColors.secondaryAccent,
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: _word.value,
                                child: Transform.translate(
                                  offset: Offset(0, 14 * (1 - _word.value)),
                                  child: const _Mark(
                                    'assets_kaylo/logo_text.svg',
                                    ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // PARTNER on a mustard pill, the partner logo's badge.
                  AnimatedBuilder(
                    animation: _badge,
                    builder: (context, _) => Opacity(
                      opacity: _badge.value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - _badge.value)),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(18, 7, 14, 7),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PARTNER',
                            style: TextStyle(
                              color: AppColors.brandPrimaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // A hairline that fills while the session is checked.
                  AnimatedBuilder(
                    animation: _bar,
                    builder: (context, _) => SizedBox(
                      width: 140,
                      height: 2,
                      child: Stack(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(1),
                            ),
                            child: const SizedBox.expand(),
                          ),
                          FractionallySizedBox(
                            widthFactor: _bar.value,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimaryBright,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The one line that belongs to both apps.
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: AnimatedBuilder(
                animation: _badge,
                builder: (context, _) => Opacity(
                  opacity: _badge.value * 0.7,
                  child: const Text(
                    'Home · Farm · Care',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 3,
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

class _Mark extends StatelessWidget {
  final String asset;
  final Color color;
  const _Mark(this.asset, this.color);

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: 220,
    height: 220,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

/// Reveals the loop from left to right as it is "drawn".
class _Reveal extends CustomClipper<Rect> {
  final double progress;
  _Reveal(this.progress);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_Reveal old) => old.progress != progress;
}

/// A soft band of light crossing the assembled mark once.
class _Sweep extends StatelessWidget {
  final double progress;
  final Widget child;
  const _Sweep({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    if (progress <= 0.001 || progress >= 0.999) return child;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        final dx = (progress * 2 - 1) * bounds.width * 1.5;
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            AppColors.brandPrimaryBright.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(bounds.translate(dx, 0));
      },
      child: child,
    );
  }
}

/// Two large radial lights that drift slowly, for depth without noise.
class _AmbientLights extends CustomPainter {
  final double t;
  const _AmbientLights(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    void light(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    light(
      Offset(
        size.width * (0.22 + 0.08 * math.sin(angle)),
        size.height * (0.24 + 0.06 * math.cos(angle)),
      ),
      size.width * 0.6,
      AppColors.brandPrimaryBright.withValues(alpha: 0.20),
    );
    light(
      Offset(
        size.width * (0.82 + 0.06 * math.cos(angle + math.pi / 3)),
        size.height * (0.80 + 0.07 * math.sin(angle + math.pi / 3)),
      ),
      size.width * 0.55,
      AppColors.secondaryAccent.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_AmbientLights old) => old.t != t;
}
