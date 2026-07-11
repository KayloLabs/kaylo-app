import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/splash_controller.dart';
import '../../../../features/home/application/home_providers.dart'; // for useMock

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

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  
  late final Animation<double> _loopReveal;
  late final Animation<double> _dotScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  bool _initialized = false;
  SplashRouteDestination? _destination;

  @override
  void initState() {
    super.initState();
    
    // Total duration: 1.5s loop + 0.25s dot + 0.3s text + 0.4s hold = 2.45s
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2450),
    );

    _loopReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.612, curve: Curves.easeInOut), // 0 to 1500ms
    );

    _dotScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.612, 0.714, curve: Curves.easeOutBack), // 1500ms to 1750ms
    );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.714, 0.836, curve: Curves.easeIn), // 1750ms to 2050ms
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.714, 0.836, curve: Curves.easeOutCubic),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitialization();
    });
  }

  Future<void> _startInitialization() async {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

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
      // Play the full choreography
      await _controller.forward();
    }
    
    _routeToDestination();
  }

  void _routeToDestination() {
    if (!mounted || _destination == null) return;
    
    // If we're forcing mock mode, replace login with dashboard for ease of testing
    final dest = _destination!;
    if (useMock && dest == SplashRouteDestination.login) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine which color looks best on the surface tint background.
    // The soft green backdrop pairs well with the dark brand primary.
    const logoColor = AppColors.brandPrimaryDark;

    return Scaffold(
      backgroundColor: AppColors.surfaceTint,
      body: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Main loop drawn from left to right
                  ClipRect(
                    clipper: RevealClipper(_loopReveal.value),
                    child: SvgPicture.asset(
                      'assets_kaylo/logo_loop.svg',
                      width: 250,
                      height: 250,
                      colorFilter: const ColorFilter.mode(logoColor, BlendMode.srcIn),
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
                        colorFilter: const ColorFilter.mode(logoColor, BlendMode.srcIn),
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
                        colorFilter: const ColorFilter.mode(logoColor, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
