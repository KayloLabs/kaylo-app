import 'package:flutter/material.dart';

class KayloLogo extends StatelessWidget {
  final double width;
  final bool isMono;
  final Color? monoColor;
  final double opacity;

  const KayloLogo({
    super.key,
    this.width = 120,
    this.isMono = false,
    this.monoColor,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // The artwork ships with this package so both apps show the same mark.
    Widget image = Image.asset(
      'assets/logo.png',
      package: 'kaylo_ui',
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to the old transparent png if logo.png is missing
        return Image.asset(
          'assets/kaylo_transparent.png',
          package: 'kaylo_ui',
          width: width,
          fit: BoxFit.contain,
        );
      },
    );

    if (isMono) {
      final color =
          monoColor ?? Theme.of(context).iconTheme.color ?? Colors.black;
      image = ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: image,
      );
    }

    if (opacity < 1.0) {
      image = Opacity(opacity: opacity, child: image);
    }

    return image;
  }
}
