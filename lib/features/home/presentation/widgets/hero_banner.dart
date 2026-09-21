import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/home_providers.dart';

class HeroSlideData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String buttonText;

  /// Substring of the catalog service name this slide promotes; the
  /// button opens that service, or a search for it if the catalog has
  /// no such service yet.
  final String serviceKeyword;

  HeroSlideData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.buttonText,
    required this.serviceKeyword,
  });
}

class HeroBanner extends ConsumerStatefulWidget {
  const HeroBanner({super.key});

  @override
  ConsumerState<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<HeroBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  List<HeroSlideData> _getSlides(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      HeroSlideData(
        title: l10n.heroCoconutTitle,
        subtitle: l10n.heroCoconutSubtitle,
        imagePath: 'assets_kaylo/3d_transparent/hero_coconut_climber_clay_v2.png',
        buttonText: l10n.heroBookNow,
        serviceKeyword: 'coconut',
      ),
      HeroSlideData(
        title: l10n.heroCleanTitle,
        subtitle: l10n.heroCleanSubtitle,
        imagePath: 'assets_kaylo/3d_transparent/hero_kerala_clay.png',
        buttonText: l10n.heroExplore,
        serviceKeyword: 'clean',
      ),
      HeroSlideData(
        title: l10n.heroPlumberTitle,
        subtitle: l10n.heroPlumberSubtitle,
        imagePath: 'assets_kaylo/3d_transparent/hero_workers_clay.png',
        buttonText: l10n.heroHireNow,
        serviceKeyword: 'plumb',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        // Hardcoded 3 slides for modulus
        int nextPage = (_currentPage + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  Future<void> _openSlide(HeroSlideData slide) async {
    KayloFeedback.press();
    final router = GoRouter.of(context);
    final keyword = slide.serviceKeyword;
    try {
      final catalog = await ref.read(fullCatalogProvider.future);
      final match = catalog
          .where((s) => s.name.toLowerCase().contains(keyword))
          .firstOrNull;
      if (match != null) {
        router.push(Routes.service(match.id));
        return;
      }
    } catch (_) {
      // Fall through to search, which shows its own error state.
    }
    router.push('${Routes.search}?q=$keyword');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 244,
      child: Stack(
        children: [
          // Background Color
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2B5C3A), // Dark Green
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: 3,
            itemBuilder: (context, index) {
              final slide = _getSlides(context)[index];
              return Stack(
                children: [
                  // Image on the right with a fade gradient mask
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppRadius.card),
                        bottomRight: Radius.circular(AppRadius.card),
                      ),
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                            ],
                            stops: [0.0, 0.4],
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.dstIn,
                        child: Image.asset(
                          slide.imagePath,
                          fit: BoxFit.contain, // Changed to contain so it's not cut off
                          alignment: Alignment.bottomRight, // Anchored to bottom right
                        ),
                      ),
                    ),
                  ),

                  // Overlay Content
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Auto-sized: the font shrinks until whole lines
                        // fit, so taller scripts (Tamil, Malayalam) never
                        // overflow and never clip a line in half.
                        Flexible(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: AutoSizeText(
                              slide.title,
                              maxLines: 3,
                              minFontSize: 15,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Flexible(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: AutoSizeText(
                              slide.subtitle,
                              maxLines: 3,
                              minFontSize: 10,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Button
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _openSlide(slide),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.l,
                                vertical: AppSpacing.s,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    slide.buttonText,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m), // space for dots
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Pagination Dots
          Positioned(
            bottom: AppSpacing.m,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _buildDot(isActive: _currentPage == index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 16 : 4,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
