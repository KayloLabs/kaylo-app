import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../features/care/application/care_calls.dart';
import '../../features/care/presentation/screens/care_call_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';
import '../../l10n/generated/app_localizations.dart';

class KayloBottomNav extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const KayloBottomNav({super.key, required this.navigationShell});

  @override
  ConsumerState<KayloBottomNav> createState() => _KayloBottomNavState();
}

class _KayloBottomNavState extends ConsumerState<KayloBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hideController;
  late final Animation<Offset> _hideAnimation;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 1.5), // Slide down completely out of view
        ).animate(
          CurvedAnimation(parent: _hideController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _hideController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      if (notification is UserScrollNotification) {
        if (notification.direction == ScrollDirection.reverse) {
          if (_hideController.status != AnimationStatus.forward) {
            _hideController.forward();
          }
        } else if (notification.direction == ScrollDirection.forward) {
          if (_hideController.status != AnimationStatus.reverse) {
            _hideController.reverse();
          }
        }
      }
    }
    return false;
  }

  int? _lastIndex;
  double? _dragX;
  int? _previewIndex;

  void _preview(double x, double width) {
    final next = (x / width).floor().clamp(0, 4);
    if (_previewIndex != next) HapticFeedback.selectionClick();
    setState(() {
      _dragX = x;
      _previewIndex = next;
    });
  }

  void _finishDrag() {
    final index = _previewIndex;
    setState(() {
      _dragX = null;
      _previewIndex = null;
    });
    if (index != null) _onTap(index);
  }

  void _cancelDrag() => setState(() {
    _dragX = null;
    _previewIndex = null;
  });

  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(incomingCareCallsProvider).asData?.value ?? [];
    final currentIndex = widget.navigationShell.currentIndex;
    // Landing on a new tab must always reveal the nav: a short screen
    // (like Care Home) can't scroll it back, stranding the user.
    if (_lastIndex != currentIndex) {
      _lastIndex = currentIndex;
      if (_hideController.status != AnimationStatus.dismissed) {
        _hideController.reverse();
      }
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            widget.navigationShell,
            if (incoming.isNotEmpty)
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                child: SafeArea(
                  child: Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.emergency),
                      title: Text(
                        AppLocalizations.of(context)!.incomingSosTitle,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.incomingSosSubtitle,
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: AppLocalizations.of(context)!.decline,
                            icon: const Icon(Icons.call_end),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(supabaseClientProvider)
                                    .rpc(
                                      'respond_care_call',
                                      params: {
                                        'p_call_id': incoming.first['call_id'],
                                        'p_action': 'declined',
                                      },
                                    );
                                ref.invalidate(incomingCareCallsProvider);
                              } catch (_) {}
                            },
                          ),
                          IconButton(
                            tooltip: AppLocalizations.of(context)!.joinCall,
                            icon: const Icon(Icons.call),
                            onPressed: () =>
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => CareCallScreen(
                                      callId:
                                          incoming.first['call_id'] as String,
                                    ),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SlideTransition(
        position: _hideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.m,
            right: AppSpacing.m,
            bottom: AppSpacing.xs,
          ),
          child: SafeArea(
            child: KayloLiquidGlass(
              borderRadius: 32, // Rounded pill
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / 5;
                  final bgColor = isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppColors.brandPrimary.withValues(alpha: 0.15);

                  final selected = _previewIndex ?? currentIndex;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (d) =>
                        _preview(d.localPosition.dx, itemWidth),
                    onHorizontalDragUpdate: (d) =>
                        _preview(d.localPosition.dx, itemWidth),
                    onHorizontalDragEnd: (_) => _finishDrag(),
                    onHorizontalDragCancel: _cancelDrag,
                    onLongPressStart: (d) =>
                        _preview(d.localPosition.dx, itemWidth),
                    onLongPressMoveUpdate: (d) =>
                        _preview(d.localPosition.dx, itemWidth),
                    onLongPressEnd: (_) => _finishDrag(),
                    onLongPressCancel: _cancelDrag,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // The moving glass pill
                        AnimatedPositioned(
                          duration: Duration(
                            milliseconds: _dragX == null ? 300 : 50,
                          ),
                          curve: Curves.easeOutCubic,
                          left: _dragX == null
                              ? currentIndex * itemWidth
                              : (_dragX! - itemWidth / 2).clamp(
                                  0,
                                  itemWidth * 4,
                                ),
                          width: itemWidth,
                          top: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(
                                        alpha: isDark ? .25 : .65,
                                      ),
                                      bgColor,
                                      Colors.white.withValues(alpha: .12),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: _dragX == null ? .45 : .85,
                                    ),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brandPrimary.withValues(
                                        alpha: .12,
                                      ),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // The icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _NavItem(
                              icon: Icons.home_outlined,
                              activeIcon: Icons.home,
                              isSelected: selected == 0,
                              isDark: isDark,
                              width: itemWidth,
                              onTap: () => _onTap(0),
                            ),
                            _NavItem(
                              icon: Icons.calendar_today_outlined,
                              activeIcon: Icons.calendar_today,
                              isSelected: selected == 1,
                              isDark: isDark,
                              width: itemWidth,
                              onTap: () => _onTap(1),
                            ),
                            _NavItem(
                              icon: Icons.favorite_outline,
                              activeIcon: Icons.favorite,
                              isSelected: selected == 2,
                              isDark: isDark,
                              width: itemWidth,
                              onTap: () => _onTap(2),
                            ),
                            _NavItem(
                              icon: Icons.chat_bubble_outline,
                              activeIcon: Icons.chat_bubble,
                              isSelected: selected == 3,
                              isDark: isDark,
                              width: itemWidth,
                              onTap: () => _onTap(3),
                            ),
                            _NavItem(
                              icon: Icons.person_outline,
                              activeIcon: Icons.person,
                              isSelected: selected == 4,
                              isDark: isDark,
                              width: itemWidth,
                              onTap: () => _onTap(4),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    KayloFeedback.tap();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final bool isDark;
  final double width;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.isDark,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : AppColors.brandPrimaryDark;
    final inactiveColor = isDark ? Colors.grey[500] : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: 48,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isSelected ? activeIcon : icon,
              key: ValueKey<bool>(isSelected),
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
