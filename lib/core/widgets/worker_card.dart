import 'package:flutter/material.dart';
import '../models/worker.dart';
import '../theme/app_spacing.dart';
import 'avatar_circle.dart';
import 'kaylo_card.dart';
import 'rating_stars.dart';

class WorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KayloCard(
      onTap: onTap,
      child: Row(
        children: [
          AvatarCircle(
            imageUrl: worker.profileImageUrl,
            fallbackText: worker.name,
            radius: 28,
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                RatingStars(rating: worker.rating, reviewCount: worker.reviewsCount),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
