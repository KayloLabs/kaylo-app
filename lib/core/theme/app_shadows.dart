import 'package:flutter/material.dart';

class AppShadows {
  // Light Mode Shadows (Soft, airy, low opacity, large blur)
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0F000000), // ~0.06 opacity black
    blurRadius: 16,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x14000000), // ~0.08 opacity black
    blurRadius: 24,
    offset: Offset(0, 4),
  );

  // Dark Mode Shadows (Subtle)
  static const BoxShadow shadowSmDark = BoxShadow(
    color: Color(0x1A000000), 
    blurRadius: 16,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowMdDark = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 24,
    offset: Offset(0, 4),
  );

  static BoxShadow getSm(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? shadowSmDark : shadowSm;
  }

  static BoxShadow getMd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? shadowMdDark : shadowMd;
  }
}
