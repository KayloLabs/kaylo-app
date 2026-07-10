import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'kaylo_card.dart';

class ServiceTile extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback onTap;

  const ServiceTile({super.key, required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KayloCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            // Placeholder for image loading from asset or network
            child: Icon(_getIconForService(service.name), color: AppColors.brandPrimary),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            service.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Starts from ₹${service.basePrice.toInt()}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForService(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('clean')) return Icons.cleaning_services;
    if (lowerName.contains('plumb')) return Icons.plumbing;
    if (lowerName.contains('electric')) return Icons.electrical_services;
    if (lowerName.contains('paint')) return Icons.format_paint;
    if (lowerName.contains('farm')) return Icons.agriculture;
    if (lowerName.contains('care')) return Icons.health_and_safety;
    return Icons.handyman;
  }
}
