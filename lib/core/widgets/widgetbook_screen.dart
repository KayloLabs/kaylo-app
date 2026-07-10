import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../models/worker.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'avatar_circle.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'kaylo_button.dart';
import 'kaylo_card.dart';
import 'kaylo_chip.dart';
import 'kaylo_list_tile.dart';
import 'kaylo_snackbar.dart';
import 'kaylo_text_field.dart';
import 'price_tag.dart';
import 'rating_stars.dart';
import 'search_bar_field.dart';
import 'section_header.dart';
import 'service_tile.dart';
import 'shimmer_box.dart';
import 'worker_card.dart';

class WidgetbookScreen extends StatelessWidget {
  const WidgetbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6), // Slight rounding for the jpeg
              child: Image.asset(
                'assets_kaylo/kaylo.jpeg', 
                height: 28, 
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Kaylo Widgetbook'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          const _Header('Buttons'),
          KayloButton(text: 'Primary Button', onPressed: () {}),
          const SizedBox(height: AppSpacing.l),
          KayloButton(
            text: 'Secondary Button',
            onPressed: () {},
            variant: KayloButtonVariant.secondary,
          ),
          const SizedBox(height: AppSpacing.l),
          KayloButton(
            text: 'Outline Button',
            onPressed: () {},
            variant: KayloButtonVariant.outline,
          ),
          const SizedBox(height: AppSpacing.l),
          KayloButton(
            text: 'With Icon',
            onPressed: () {},
            icon: Icons.shopping_cart,
          ),
          const SizedBox(height: AppSpacing.l),
          KayloButton(text: 'Loading', onPressed: () {}, isLoading: true),

          const _Header('Inputs'),
          const KayloTextField(label: 'Full Name', hintText: 'Enter your name'),
          const SizedBox(height: AppSpacing.l),
          const SearchBarField(),

          const _Header('Chips & Tags'),
          Wrap(
            spacing: AppSpacing.s,
            children: const [
              KayloChip(label: 'Brand', variant: KayloChipVariant.brand),
              KayloChip(
                label: 'Success',
                variant: KayloChipVariant.success,
                icon: Icons.check,
              ),
              KayloChip(label: 'Error', variant: KayloChipVariant.error),
              KayloChip(label: 'Warning', variant: KayloChipVariant.warning),
              KayloChip(label: 'Neutral', variant: KayloChipVariant.neutral),
            ],
          ),

          const _Header('Price & Rating'),
          const PriceTag(amount: 1500, isLarge: true),
          const SizedBox(height: AppSpacing.s),
          const RatingStars(rating: 4.8, reviewCount: 124),

          const _Header('Avatar'),
          Row(
            children: const [
              AvatarCircle(fallbackText: 'Nimal D', radius: 32),
              SizedBox(width: AppSpacing.m),
              AvatarCircle(fallbackText: 'User Name'),
            ],
          ),

          const _Header('Cards & Tiles'),
          KayloCard(
            child: const Text(
              'This is a basic KayloCard with padding and border.',
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          KayloListTile(
            title: const Text('List Tile Title'),
            subtitle: const Text('This is a secondary subtitle'),
            leading: const Icon(Icons.person, color: AppColors.brandPrimary),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),

          const _Header('Domain Specific'),
          Row(
            children: [
              Expanded(
                child: ServiceTile(
                  service: ServiceItem(
                    id: '1',
                    name: 'Plumbing',
                    category: 'home',
                    description: '',
                    iconPath: '',
                    basePrice: 500,
                  ),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: ServiceTile(
                  service: ServiceItem(
                    id: '2',
                    name: 'Cleaning',
                    category: 'home',
                    description: '',
                    iconPath: '',
                    basePrice: 800,
                  ),
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          WorkerCard(
            worker: Worker(
              id: '1',
              name: 'Raju K.',
              profileImageUrl: '',
              rating: 4.8,
              reviewsCount: 120,
              skillIds: [],
              location: 'Kochi',
              trustScore: 90,
            ),
            onTap: () {},
          ),

          const _Header('States & Shimmer'),
          const ShimmerBox(width: double.infinity, height: 100),
          const SizedBox(height: AppSpacing.l),
          EmptyState(
            title: 'No Data Found',
            description: 'We could not find anything here.',
            actionText: 'Refresh',
            onActionPressed: () {},
          ),
          const SizedBox(height: AppSpacing.l),
          ErrorState(
            message: 'Failed to load content from the server.',
            onRetry: () {},
          ),

          const _Header('Snackbars'),
          KayloButton(
            text: 'Show Success Snackbar',
            onPressed: () => KayloSnackbar.showSuccess(
              context,
              'Action completed successfully!',
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          KayloButton(
            text: 'Show Error Snackbar',
            onPressed: () =>
                KayloSnackbar.showError(context, 'Something went wrong.'),
            variant: KayloButtonVariant.secondary,
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.m),
      child: SectionHeader(title: title),
    );
  }
}
