import 'package:flutter/material.dart';

class OnboardingSlideData {
  final String headline;
  final String subtext;
  final Color accentColor;
  final String imagePath;
  final IconData? fallbackIcon;

  const OnboardingSlideData({
    required this.headline,
    required this.subtext,
    required this.accentColor,
    required this.imagePath,
    this.fallbackIcon,
  });
}
