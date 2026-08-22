import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/care_mode_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_mode_provider.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_list_tile.dart';
import '../../../../core/widgets/language_selector_sheet.dart';
import '../../../../core/widgets/section_header.dart';

const _notificationsKey = 'notifications_enabled';

final _notificationsEnabledProvider =
    NotifierProvider<_NotificationsNotifier, bool>(_NotificationsNotifier.new);

class _NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(_notificationsKey) ?? true;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_notificationsKey, enabled);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _languageNames = {
    'en': 'English',
    'ml': 'മലയാളം',
    'hi': 'हिंदी',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final careMode = ref.watch(careModeProvider);
    final notifications = ref.watch(_notificationsEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.m),
                _ThemeModeSelector(
                  selected: themeMode,
                  onChanged: (mode) =>
                      ref.read(themeModeProvider.notifier).setThemeMode(mode),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            padding: EdgeInsets.zero,
            child: KayloListTile(
              leading: const _SettingIcon(
                icon: Icons.translate_rounded,
                color: AppColors.homeAccent,
              ),
              title: const Text('Language'),
              subtitle: Text(_languageNames[locale.languageCode] ?? 'English'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => const LanguageSelectorSheet(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          const SectionHeader(title: 'Accessibility'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            padding: EdgeInsets.zero,
            child: KayloListTile(
              leading: const _SettingIcon(
                icon: Icons.favorite_rounded,
                color: AppColors.careAccent,
              ),
              title: const Text('Kaylo Care Mode'),
              subtitle: const Text('Larger text and simpler screens for seniors'),
              trailing: Switch.adaptive(
                value: careMode,
                activeThumbColor: AppColors.careAccent,
                onChanged: (value) =>
                    ref.read(careModeProvider.notifier).setEnabled(value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          const SectionHeader(title: 'Notifications'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            padding: EdgeInsets.zero,
            child: KayloListTile(
              leading: const _SettingIcon(
                icon: Icons.notifications_rounded,
                color: AppColors.accent,
              ),
              title: const Text('Push notifications'),
              subtitle: const Text('Booking updates and offers'),
              trailing: Switch.adaptive(
                value: notifications,
                onChanged: (value) => ref
                    .read(_notificationsEnabledProvider.notifier)
                    .setEnabled(value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          const SectionHeader(title: 'About'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const KayloListTile(
                  leading: _SettingIcon(
                    icon: Icons.info_rounded,
                    color: AppColors.brandPrimary,
                  ),
                  title: Text('Version'),
                  trailing: Text('1.0.0'),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                KayloListTile(
                  leading: const _SettingIcon(
                    icon: Icons.description_rounded,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text('Terms & Privacy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              'Made with ♥ in Kerala',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

/// Animated three-way segmented control: System / Light / Dark.
class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({required this.selected, required this.onChanged});

  static const _options = [
    (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
    (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final index = _options.indexWhere((o) => o.$1 == selected);
    final count = _options.length;

    // The label Row defines the height, and the sliding pill is aligned as a
    // fraction of the track, so the control stays intact at any text scale.
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                count == 1 ? 0 : (index / (count - 1)) * 2 - 1,
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (mode, icon, label) in _options)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => onChanged(mode),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: mode == selected
                                ? AppColors.brandPrimary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: mode == selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
