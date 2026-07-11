import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/kaylo_liquid_glass.dart';
import 'greeting_section.dart';

class GreetingHeader extends StatelessWidget {
  final String location;
  final int notificationCount;
  final String userName;

  const GreetingHeader({
    super.key,
    required this.location,
    required this.notificationCount,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Greeting replacing logo
        GreetingSection(userName: userName),

        // Location & Bell
        Row(
          children: [
            // Location Pill (Liquid Glass style)
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.s),
            // Bell Icon with Badge
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                KayloLiquidGlass(
                  borderRadius: 20.0,
                  padding: const EdgeInsets.all(AppSpacing.s),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
