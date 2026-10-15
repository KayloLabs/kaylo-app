import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'liquid_tab_bar.dart';
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
    if (MediaQuery.disableAnimationsOf(context)) return false;
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
  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    // Landing on a new tab must always reveal the nav: a short screen
    // (like Care Home) can't scroll it back, stranding the user.
    if (_lastIndex != currentIndex) {
      _lastIndex = currentIndex;
      if (_hideController.status != AnimationStatus.dismissed) {
        _hideController.reverse();
      }
    }

    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(children: [widget.navigationShell]),
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
            child: LiquidTabBar(
              index: currentIndex,
              onSelected: _onTap,
              labels: [
                AppLocalizations.of(context)?.home ?? 'Home',
                AppLocalizations.of(context)?.myBookings ?? 'Bookings',
                AppLocalizations.of(context)?.care ?? 'Care',
                AppLocalizations.of(context)?.messages ?? 'Messages',
                AppLocalizations.of(context)?.profile ?? 'Profile',
              ],
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
