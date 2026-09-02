import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/splash_controller.dart';

class RevealClipper extends CustomClipper<Rect> {
  final double progress;
  RevealClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(RevealClipper oldClipper) => oldClipper.progress != progress;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _ambient;

  late final Animation<double> _loopReveal;
  late final Animation<double> _dotScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _shimmer;
  late final Animation<double> _taglineFade;

  bool _exiting = false;
  SplashRouteDestination? _destination;

  @override
  void initState() {
    super.initState();

    // Choreography: 1.5s loop + 0.25s dot + 0.3s text + 0.6s shimmer/hold = 2.65s
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2650),
    );

    // Slow ambient drift for the background light blobs.
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _loopReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.566, curve: Curves.easeInOut), // 0-1500ms
    );

    _dotScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.566, 0.660, curve: Curves.easeOutBack), // 1500-1750ms
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.660, 0.774, curve: Curves.easeIn), // 1750-2050ms
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.660, 0.774, curve: Curves.easeOutCubic),
    ));

    // Light sweep across the assembled logo during the closing hold.
    _shimmer = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.790, 0.980, curve: Curves.easeInOut), // 2090-2600ms
    );

    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.774, 0.900, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialization();
    });
  }

  Future<void> _startInitialization() async {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (!disableAnimations) {
      _ambient.repeat();
    }

    // Start initialization logic concurrently with animation
    final initFuture = ref.read(splashControllerProvider.notifier).initializeApp();

    // Wait for the app state to initialize
    await initFuture;
    _destination = ref.read(splashControllerProvider).value;

    if (disableAnimations) {
      // Fast path for reduced motion
      _controller.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 500));
    } else {
      // Play the full choreography, then fade the whole scene out.
      await _controller.forward();
      if (mounted) setState(() => _exiting = true);
      await Future.delayed(const Duration(milliseconds: 260));
    }

    _routeToDestination();
  }

  void _routeToDestination() {
    if (!mounted || _destination == null) return;

    // TODO(M2): drop this bypass once real auth screens land. Until then
    // the login route is a placeholder, so always continue to the
    // dashboard — the catalog reads work anonymously on live Supabase too.
    final dest = _destination!;
    if (dest == SplashRouteDestination.login) {
      context.go(Routes.dashboard);
      return;
    }

    switch (dest) {
      case SplashRouteDestination.onboarding:
        context.go(Routes.onboarding);
        break;
      case SplashRouteDestination.login:
        context.go(Routes.login);
        break;
      case SplashRouteDestination.dashboard:
        context.go(Routes.dashboard);
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoColor =
        isDark ? AppColors.brandPrimaryBright : AppColors.brandPrimaryDark;
    final backgroundColor =
        isDark ? AppColors.surfaceMutedDark : AppColors.surfaceTint;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedOpacity(
        opacity: _exiting ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: Stack(
          children: [
            // Ambient drifting light, painted behind the logo.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ambient,
                builder: (context, _) => CustomPaint(
                  painter: _AmbientGlowPainter(
                    t: _ambient.value,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return _LogoShimmer(
                          progress: _shimmer.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Main loop drawn from left to right
                              ClipRect(
                                clipper: RevealClipper(_loopReveal.value),
                                child: SvgPicture.asset(
                                  'assets_kaylo/logo_loop.svg',
                                  width: 250,
                                  height: 250,
                                  colorFilter: ColorFilter.mode(
                                      logoColor, BlendMode.srcIn),
                                ),
                              ),

                              // Dot pops in
                              Transform.scale(
                                scale: _dotScale.value,
                                child: Opacity(
                                  opacity: _dotScale.value.clamp(0.0, 1.0),
                                  child: SvgPicture.asset(
                                    'assets_kaylo/logo_dot.svg',
                                    width: 250,
                                    height: 250,
                                    colorFilter: ColorFilter.mode(
                                        logoColor, BlendMode.srcIn),
                                  ),
                                ),
                              ),

                              // Wordmark fades and slides up
                              Opacity(
                                opacity: _textFade.value,
                                child: SlideTransition(
                                  position: _textSlide,
                                  child: SvgPicture.asset(
                                    'assets_kaylo/logo_text.svg',
                                    width: 250,
                                    height: 250,
                                    colorFilter: ColorFilter.mode(
                                        logoColor, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Tagline settles in under the logo.
                  AnimatedBuilder(
                    animation: _taglineFade,
                    builder: (context, _) => Opacity(
                      opacity: _taglineFade.value,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - _taglineFade.value)),
                        child: Text(
                          'Home · Farm · Care',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                                letterSpacing: 3.0,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sweeps a soft light band across the logo via ShaderMask once it has
/// fully assembled. At progress 0 or 1 the band sits offscreen.
class _LogoShimmer extends StatelessWidget {
  final double progress;
  final Widget child;

  const _LogoShimmer({required this.progress, required this.child});

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
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ).createShader(bounds.translate(dx, 0));
      },
      child: child,
    );
  }
}

/// Two large, very soft radial glows that slowly orbit — gives the flat
/// backdrop a sense of depth without stealing attention from the logo.
class _AmbientGlowPainter extends CustomPainter {
  final double t;
  final bool isDark;

  _AmbientGlowPainter({required this.t, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;

    void glow(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    final green = AppColors.brandPrimaryBright
        .withOpacity(isDark ? 0.10 : 0.16);
    final amber =
        AppColors.secondaryAccent.withOpacity(isDark ? 0.05 : 0.10);

    glow(
      Offset(
        size.width * (0.25 + 0.08 * math.sin(angle)),
        size.height * (0.22 + 0.06 * math.cos(angle)),
      ),
      size.width * 0.55,
      green,
    );
    glow(
      Offset(
        size.width * (0.80 + 0.06 * math.cos(angle + math.pi / 3)),
        size.height * (0.78 + 0.07 * math.sin(angle + math.pi / 3)),
      ),
      size.width * 0.6,
      amber,
    );
  }

  @override
  bool shouldRepaint(_AmbientGlowPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.isDark != isDark;
}
