import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_logo.dart';
import '../../domain/models/onboarding_slide_data.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      headline: 'Welcome', // Handled specially
      subtext: '',
      accentColor: AppColors.brandPrimary,
      imagePath: '',
      fallbackIcon: Icons.star,
    ),
    OnboardingSlideData(
      headline: 'Premium Home Services',
      subtext: 'Top-rated professionals for plumbing, electrical, and cleaning. Book instantly, stress less.',
      accentColor: AppColors.homeAccent,
      imagePath: 'assets_kaylo/3d_transparent/hero_kerala_clay.png',
      fallbackIcon: Icons.home_rounded,
    ),
    OnboardingSlideData(
      headline: 'Expert Farm & Garden Care',
      subtext: 'From skilled coconut climbers to expert gardeners. Nurture your land with trusted hands.',
      accentColor: AppColors.farmAccent,
      imagePath: 'assets_kaylo/3d_transparent/hero_coconut_climber_clay_v2.png',
      fallbackIcon: Icons.agriculture_rounded,
    ),
    OnboardingSlideData(
      headline: 'Family Care, Reimagined',
      subtext: 'Manage services, reminders, and support for your parents remotely. True peace of mind.',
      accentColor: AppColors.careAccent,
      imagePath: 'assets_kaylo/3d_transparent/mode_care.png',
      fallbackIcon: Icons.favorite_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(storageServiceProvider).setOnboardingSeen(true);
    context.pushReplacement(Routes.signup);
  }

  void _nextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHero = _currentIndex == 0;
    
    return Scaffold(
      backgroundColor: AppColors.surfaceTint,
      body: SafeArea(
        child: Column(
          children: [
            // Top Nav Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo on left only for non-hero slides
                  isHero ? const SizedBox(width: 80) : const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.s),
                    child: KayloLogo(width: 80),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeroSlide();
                  return _buildNormalSlide(_slides[index], index);
                },
              ),
            ),
            
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _buildDot(index, isHero),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    child: KayloButton(
                      text: _currentIndex == _slides.length - 1 ? 'Get Started' : 'Next',
                      onPressed: _nextPage,
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

  Widget _buildHeroSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          
          // Centered Kaylo Logo (Swiggy Style)
          const KayloLogo(width: 120),
          
          const SizedBox(height: AppSpacing.xxxl),
          
          // Fanned Cards Graphic (Swiggy Style)
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Left Card (Farm)
                Transform.translate(
                  offset: const Offset(-80, 30),
                  child: Transform.rotate(
                    angle: -0.25,
                    child: _buildWelcomeCard('assets_kaylo/3d_transparent/hero_coconut_climber_clay_v2.png', AppColors.farmAccent),
                  ),
                ),
                // Right Card (Care)
                Transform.translate(
                  offset: const Offset(80, 30),
                  child: Transform.rotate(
                    angle: 0.25,
                    child: _buildWelcomeCard('assets_kaylo/3d_transparent/hero_workers_clay.png', AppColors.careAccent),
                  ),
                ),
                // Center Card (Home)
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Transform.scale(
                    scale: 1.15,
                    child: _buildWelcomeCard('assets_kaylo/3d_transparent/hero_kerala_clay.png', AppColors.homeAccent),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxxl),
          
          // Short, Memorable Tagline
          Text(
            'One app for home, farm & care in minutes!',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String assetPath, Color shadowColor) {
    return Container(
      width: 140,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Center(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildNormalSlide(OnboardingSlideData slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Fallback
          Expanded(
            flex: 5,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Hero(
                  tag: 'onboarding_img_$index',
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        slide.fallbackIcon,
                        size: 100,
                        color: slide.accentColor,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.l),
                Text(
                  slide.headline,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  slide.subtext,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, bool isHero) {
    final isActive = _currentIndex == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandPrimary : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
