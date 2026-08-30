import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/generated/app_localizations.dart';

class HeroSlideData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String buttonText;

  HeroSlideData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.buttonText,
  });
}

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
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
      ),
      HeroSlideData(
        title: l10n.heroCleanTitle,
        subtitle: l10n.heroCleanSubtitle,
        imagePath: 'assets_kaylo/3d_transparent/hero_kerala_clay.png',
        buttonText: l10n.heroExplore,
      ),
      HeroSlideData(
        title: l10n.heroPlumberTitle,
        subtitle: l10n.heroPlumberSubtitle,
        imagePath: 'assets_kaylo/3d_transparent/hero_workers_clay.png',
        buttonText: l10n.heroHireNow,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
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
                        // Flexible + ellipsis: Tamil and Malayalam copy runs
                        // taller than English and must never overflow the
                        // fixed banner height.
                        Flexible(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Text(
                              slide.title,
                              maxLines: 4,
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
                            child: Text(
                              slide.subtitle,
                              maxLines: 3,
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
                            onTap: () => KayloFeedback.press(),
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
