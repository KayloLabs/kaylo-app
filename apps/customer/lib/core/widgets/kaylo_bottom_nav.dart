import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../features/care/application/care_calls.dart';
import '../../features/care/presentation/screens/care_call_screen.dart';
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
