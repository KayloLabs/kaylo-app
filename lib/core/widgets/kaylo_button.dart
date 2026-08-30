import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

enum KayloButtonVariant { primary, secondary, outline }

class KayloButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final KayloButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  const KayloButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = KayloButtonVariant.primary,
    this.isLoading = false,
    this.icon,
  });

  /// Haptic + click on every press, from one place for all variants.
  VoidCallback? get _handlePress {
    if (isLoading || onPressed == null) return null;
    return () {
      KayloFeedback.press();
      onPressed!();
    };
  }

  @override
  Widget build(BuildContext context) {
    final content = isLoading
        ? _buildLoadingIndicator()
        : _buildContent(context);

    if (variant == KayloButtonVariant.primary) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          boxShadow: [AppShadows.getSm(context)],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3E8B5E),
              Color(0xFF2F7A4F),
            ], // Top highlight to bottom shade
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          child: InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: _handlePress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(
                      alpha: 0.3,
                    ), // Top inner-highlight
                    width: 1.0,
                  ),
                ),
              ),
              alignment: Alignment.center,
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _handlePress,
        style: _getButtonStyle(context),
        child: content,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    Widget content;
    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          // Long localized labels (Tamil, Malayalam) shrink to fit
          // instead of overflowing the button.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    } else {
      content = Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );
    }

    return content;
  }

  Widget _buildLoadingIndicator() {
    final color = variant == KayloButtonVariant.primary
        ? AppColors.surface
        : AppColors.brandPrimary;
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(color: color, strokeWidth: 2.5),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(100),
    );

    switch (variant) {
      case KayloButtonVariant.primary:
        return ElevatedButton.styleFrom(); // Unused, handled above
      case KayloButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
          foregroundColor: AppColors.brandPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        );
      case KayloButtonVariant.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.brandPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: shape,
          side: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.0, // Thinner border
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        );
    }
  }
}
