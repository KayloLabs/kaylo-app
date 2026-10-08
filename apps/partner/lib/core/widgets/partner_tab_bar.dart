import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';

/// Descriptor for a destination tab within [PartnerTabBar].
class PartnerTabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const PartnerTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// A liquid glass bottom navigation bar for the partner app.
///
/// Built on [KayloLiquidGlass] from `kaylo_ui` and modelled on the customer
/// app's fluid navigation bar with smooth physics and sliding lens indicator.
class PartnerTabBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final List<PartnerTabItem> items;

  const PartnerTabBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.items,
  });

  @override
  State<PartnerTabBar> createState() => _PartnerTabBarState();
}

class _PartnerTabBarState extends State<PartnerTabBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.currentIndex.toDouble(),
  );

  bool _dragging = false;
  int? _previewIndex;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _settle(double target, {double? velocity}) {
    if (_reduceMotion) {
      _position.value = target;
      return;
    }
    _position.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 420, damping: 34),
        _position.value,
        target,
        (velocity ?? _position.velocity).clamp(-8.0, 8.0),
      ),
    );
  }

  @override
  void didUpdateWidget(PartnerTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_dragging) {
      _settle(widget.currentIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _handleDrag(double localDx, double itemWidth, bool rtl) {
    if (widget.items.isEmpty) return;
    final maxIndex = widget.items.length - 1;
    final logicalX = rtl ? (itemWidth * widget.items.length) - localDx : localDx;
    final next = (logicalX / itemWidth).floor().clamp(0, maxIndex);

    if (_previewIndex != next) {
      KayloFeedback.selection();
    }

    setState(() {
      _dragging = true;
      _previewIndex = next;
    });

    final targetPos = (logicalX / itemWidth - 0.5).clamp(0.0, maxIndex.toDouble());
    _position.value = targetPos;
  }

  void _endDrag({bool cancel = false}) {
    if (!_dragging) return;
    final maxIndex = widget.items.length - 1;
    final next = cancel
        ? widget.currentIndex
        : (_previewIndex ?? widget.currentIndex).clamp(0, maxIndex);

    setState(() {
      _dragging = false;
      _previewIndex = null;
    });

    _settle(next.toDouble());

    if (!cancel && next != widget.currentIndex) {
      widget.onSelected(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final itemCount = widget.items.length;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: KayloLiquidGlass(
        borderRadius: 32,
        colorOverlay: isDark
            ? const Color(0xFF16211B).withValues(alpha: 0.25)
            : const Color(0xFFFFFFFF).withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / math.max(1, itemCount);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) =>
                  _handleDrag(d.localPosition.dx, itemWidth, isRtl),
              onHorizontalDragUpdate: (d) =>
                  _handleDrag(d.localPosition.dx, itemWidth, isRtl),
              onHorizontalDragEnd: (_) => _endDrag(),
              onHorizontalDragCancel: () => _endDrag(cancel: true),
              child: SizedBox(
                height: 56,
                child: AnimatedBuilder(
                  animation: _position,
                  builder: (context, _) {
                    final p = _position.value.clamp(0.0, (itemCount - 1).toDouble());
                    final physicalPos = isRtl ? (itemCount - 1) - p : p;

                    return Stack(
                      children: [
                        // Sliding active pill lens indicator
                        Positioned(
                          left: physicalPos * itemWidth,
                          width: itemWidth,
                          top: 2,
                          bottom: 2,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.brandPrimary.withValues(alpha: 0.28)
                                  : AppColors.brandPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.brandPrimary.withValues(alpha: 0.5)
                                    : AppColors.brandPrimary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ),

                        // Destination items row
                        Row(
                          children: List.generate(itemCount, (i) {
                            final selected = (_previewIndex ?? widget.currentIndex) == i;
                            final influence = (1.0 - (p - i).abs()).clamp(0.0, 1.0);
                            final item = widget.items[i];

                            // Colors with contrast > 4.5:1 against glass in both themes
                            final activeTextColor = isDark
                                ? Colors.white
                                : AppColors.brandPrimaryDark;
                            final inactiveTextColor = isDark
                                ? const Color(0xFFCCCCCC)
                                : const Color(0xFF4A5568);

                            final activeIconColor = isDark
                                ? AppColors.brandPrimaryBright
                                : AppColors.brandPrimary;
                            final inactiveIconColor = isDark
                                ? const Color(0xFFBBBBBB)
                                : const Color(0xFF6B7280);

                            final currentColor = Color.lerp(
                              inactiveTextColor,
                              activeTextColor,
                              influence,
                            )!;

                            final currentIconColor = Color.lerp(
                              inactiveIconColor,
                              activeIconColor,
                              influence,
                            )!;

                            return Expanded(
                              child: Semantics(
                                label: item.label,
                                selected: selected,
                                button: true,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () {
                                    KayloFeedback.selection();
                                    _settle(i.toDouble());
                                    widget.onSelected(i);
                                  },
                                  child: SizedBox(
                                    height: 56,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Transform.scale(
                                          scale: _reduceMotion
                                              ? 1.0
                                              : (1.0 + 0.08 * influence),
                                          child: Icon(
                                            selected ? item.selectedIcon : item.icon,
                                            size: 22,
                                            color: currentIconColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Flexible(
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: currentColor,
                                              letterSpacing: 0.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
