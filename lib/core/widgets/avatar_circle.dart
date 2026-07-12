import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarCircle extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;
  final double radius;

  const AvatarCircle({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.surfaceTint,
      backgroundImage: _getImageProvider(),
      child: _getImageProvider() == null
          ? Text(
              _getInitials(),
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }

  ImageProvider? _getImageProvider() {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return NetworkImage(imageUrl!);
  }

  String _getInitials() {
    if (fallbackText.isEmpty) return '?';
    final parts = fallbackText.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fallbackText[0].toUpperCase();
  }
}
