import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'kaylo_liquid_glass.dart';

class KayloBottomNav extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const KayloBottomNav({super.key, required this.navigationShell});

  @override
  State<KayloBottomNav> createState() => _KayloBottomNavState();
}

class _KayloBottomNavState extends State<KayloBottomNav> with SingleTickerProviderStateMixin {
  late final AnimationController _hideController;
  late final Animation<Offset> _hideAnimation;

  @override
  void initState() {
    super.initState();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1.5), // Slide down completely out of view
    ).animate(CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOut,
    ));
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: widget.navigationShell,
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
                  final itemWidth = constraints.maxWidth / 4;
                  final bgColor = isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.brandPrimary.withValues(alpha: 0.15);
                  
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // The moving glass pill
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        left: currentIndex * itemWidth,
                        width: itemWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(24),
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
                            isSelected: currentIndex == 0,
                            isDark: isDark,
                            width: itemWidth,
                            onTap: () => _onTap(0),
                          ),
                          _NavItem(
                            icon: Icons.calendar_today_outlined,
                            activeIcon: Icons.calendar_today,
                            isSelected: currentIndex == 1,
                            isDark: isDark,
                            width: itemWidth,
                            onTap: () => _onTap(1),
                          ),
                          _NavItem(
                            icon: Icons.chat_bubble_outline,
                            activeIcon: Icons.chat_bubble,
                            isSelected: currentIndex == 2,
                            isDark: isDark,
                            width: itemWidth,
                            onTap: () => _onTap(2),
                          ),
                          _NavItem(
                            icon: Icons.person_outline,
                            activeIcon: Icons.person,
                            isSelected: currentIndex == 3,
                            isDark: isDark,
                            width: itemWidth,
                            onTap: () => _onTap(3),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
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
        height: 40,
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
