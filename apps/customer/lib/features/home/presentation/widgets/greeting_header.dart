import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';
import 'greeting_section.dart';
import 'location_picker_sheet.dart';

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
        // Greeting must flex: Malayalam/Hindi strings run long and would
        // otherwise overflow the fixed-width location pill and bell.
        Expanded(child: GreetingSection(userName: userName)),
        const SizedBox(width: AppSpacing.s),

        // Location & Bell
        Row(
          children: [
            // Location pill: tap to change it (GPS or typed).
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () {
                  KayloFeedback.tap();
                  showLocationPickerSheet(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.s,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
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
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Bell Icon with Badge
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                KayloLiquidGlass(
                  borderRadius: 20.0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        KayloFeedback.tap();
                        context.push(Routes.notifications);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: IgnorePointer(
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
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
