import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_list_tile.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/family_repository.dart';

final familyListProvider = FutureProvider.autoDispose<List<AppUser>>((ref) {
  return ref.watch(familyRepositoryProvider).getMyParents();
});

class FamilyDashboardScreen extends ConsumerWidget {
  const FamilyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Dashboard'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(familyListProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              const SectionHeader(title: 'My Parents'),
              const SizedBox(height: AppSpacing.m),
              familyAsync.when(
                data: (parents) {
                  if (parents.isEmpty) {
                    return KayloCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          Icon(Icons.family_restroom_rounded, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            'No family members linked yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  return KayloCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < parents.length; i++) ...[
                          KayloListTile(
                            leading: AvatarCircle(
                              fallbackText: parents[i].firstName,
                              radius: 20,
                            ),
                            title: Text('${parents[i].firstName} ${parents[i].lastName}'),
                            subtitle: Text(parents[i].phone),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              KayloSnackbar.showInfo(context, 'Managing ${parents[i].firstName} soon');
                            },
                          ),
                          if (i < parents.length - 1)
                            Divider(height: 1, indent: 72, color: isDark ? AppColors.borderDark : AppColors.border),
                        ]
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error: $err', style: TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              KayloButton(
                text: 'Add Family Member',
                icon: Icons.person_add_rounded,
                variant: KayloButtonVariant.secondary,
                onPressed: () {
                  _showAddParentDialog(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddParentDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Parent'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+91 98470 12345',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final phone = controller.text.trim();
              if (phone.isEmpty) return;
              
              Navigator.pop(context); // Close dialog
              
              try {
                await ref.read(familyRepositoryProvider).addParent(phone);
                ref.invalidate(familyListProvider); // Refresh list
                if (context.mounted) KayloSnackbar.showInfo(context, 'Added successfully');
              } catch (e) {
                if (context.mounted) KayloSnackbar.showError(context, e.toString());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
