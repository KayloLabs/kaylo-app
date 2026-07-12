import 'dart:ui';
import 'package:flutter/material.dart';

class KayloLiquidGlass extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? colorOverlay;

  const KayloLiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.width,
    this.height,
    this.colorOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 3. Light, controlled tint (whisper of warm white / cool dark or custom overlay)
    final tintColor = colorOverlay ?? (isDark 
        ? const Color(0xFF16211B).withValues(alpha: 0.15) 
        : const Color(0xFFFAF8F3).withValues(alpha: 0.15));

    // 2. Bright specular rim (gradient border effect)
    final topRimColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.6);
    final bottomRimColor = isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // 4. Depth and float: soft, wide, diffuse drop shadow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Layer 1: Backdrop blur (light blur for legibility + clear tint)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: tintColor),
              ),
            ),
            
            // Layer 2: Gradient refraction layer (approximating edge-lensing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.8),
                    radius: 2.0,
                    colors: [
                      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.0),
                      isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            
            // Layer 3: Specular rim highlight & faint dark edge
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.only(top: 1.5, left: 0.5, right: 0.5, bottom: 1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [topRimColor, Colors.white.withValues(alpha: 0.0), bottomRimColor],
                    stops: const [0.0, 0.2, 1.0],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    // extremely subtle inner reflection glow
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            
            // Content layer (sizes the Stack)
            Container(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
