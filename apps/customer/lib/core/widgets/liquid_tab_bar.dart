import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';

/// One continuous lens. Dragging previews a destination; release commits it.
/// A cancelled gesture returns to the current tab without navigating.
class LiquidTabBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onSelected;
  final List<String> labels;
  const LiquidTabBar({
    super.key,
    required this.index,
    required this.onSelected,
    required this.labels,
  });
  @override
  State<LiquidTabBar> createState() => _LiquidTabBarState();
}

class _LiquidTabBarState extends State<LiquidTabBar>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );
  bool _dragging = false;
  int? _preview;
  static const _icons = [
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.favorite_outline,
    Icons.chat_bubble_outline,
    Icons.person_outline,
  ];
  static const _active = [
    Icons.home_rounded,
    Icons.calendar_today_rounded,
    Icons.favorite_rounded,
    Icons.chat_bubble_rounded,
    Icons.person_rounded,
  ];

  bool get _reduce => MediaQuery.disableAnimationsOf(context);
  void _settle(double target) {
    if (_reduce) {
      _position.value = target;
      return;
    }
    _position.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 420, damping: 34),
        _position.value,
        target,
        _position.velocity.clamp(-8.0, 8.0),
      ),
    );
  }

  @override
  void didUpdateWidget(LiquidTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !_dragging) {
      _settle(widget.index.toDouble());
    }
  }

  void _drag(double x, double width, bool rtl) {
    final logical = rtl ? width * 5 - x : x;
    final position = (logical / width - .5).clamp(0.0, 4.0);
    final next = (logical / width).floor().clamp(0, 4);
    if (_preview != next) KayloFeedback.selection();
    setState(() {
      _dragging = true;
      _preview = next;
    });
    _position.value = position;
  }

  void _end({bool cancel = false}) {
    if (!_dragging) return;
    final next = cancel ? widget.index : _preview ?? widget.index;
    setState(() {
      _dragging = false;
      _preview = null;
    });
    _settle(next.toDouble());
    if (!cancel && next != widget.index) widget.onSelected(next);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final contrast = MediaQuery.highContrastOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return KayloLiquidGlass(
      borderRadius: 34,
      colorOverlay: contrast
          ? Theme.of(context).colorScheme.surface
          : (dark ? const Color(0xFF14271D) : const Color(0xFFF7FAF6))
                .withValues(alpha: dark ? .62 : .34),
      padding: const EdgeInsets.all(7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 5;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _drag(d.localPosition.dx, width, rtl),
            onHorizontalDragUpdate: (d) =>
                _drag(d.localPosition.dx, width, rtl),
            onHorizontalDragEnd: (_) => _end(),
            onHorizontalDragCancel: () => _end(cancel: true),
            onLongPressStart: (d) => _drag(d.localPosition.dx, width, rtl),
            onLongPressMoveUpdate: (d) => _drag(d.localPosition.dx, width, rtl),
            onLongPressEnd: (_) => _end(),
            onLongPressCancel: () => _end(cancel: true),
            child: AnimatedBuilder(
              animation: _position,
              builder: (context, _) {
                final p = _position.value.clamp(0.0, 4.0);
                final physical = rtl ? 4 - p : p;
                final stretch = _reduce
                    ? 0.0
                    : math.min(.13, _position.velocity.abs() * .014);
                return SizedBox(
                  height: 52,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: physical * width,
                        top: 1,
                        width: width,
                        height: 50,
                        child: IgnorePointer(
                          child: AnimatedScale(
                            scale: _dragging && !_reduce ? 1.08 : 1,
                            duration: _reduce
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: Transform.scale(
                              scaleX: 1 + stretch,
                              scaleY: 1 - stretch * .35,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 6,
                                    sigmaY: 6,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: LinearGradient(
                                        begin: Alignment(
                                          -.8 + physical * .4,
                                          -1,
                                        ),
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withValues(
                                            alpha: dark ? .3 : .76,
                                          ),
                                          AppColors.brandPrimary.withValues(
                                            alpha: dark ? .22 : .12,
                                          ),
                                          Colors.white.withValues(
                                            alpha: dark ? .12 : .44,
                                          ),
                                        ],
                                        stops: const [0, .58, 1],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: dark ? .45 : .85,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          final influence = (1 - (p - i).abs()).clamp(0.0, 1.0);
                          final selected = (_preview ?? widget.index) == i;
                          return Semantics(
                            label: widget.labels[i],
                            selected: selected,
                            button: true,
                            child: Tooltip(
                              triggerMode: TooltipTriggerMode.manual,
                              message: widget.labels[i],
                              child: SizedBox(
                                width: width,
                                height: 52,
                                child: IconButton(
                                  onPressed: () {
                                    _settle(i.toDouble());
                                    widget.onSelected(i);
                                  },
                                  style: IconButton.styleFrom(
                                    highlightColor: Colors.transparent,
                                  ),
                                  icon: Transform.translate(
                                    offset: Offset(
                                      0,
                                      _reduce ? 0 : -1.5 * influence,
                                    ),
                                    child: Transform.scale(
                                      scale: _reduce ? 1 : 1 + .09 * influence,
                                      child: Icon(
                                        selected ? _active[i] : _icons[i],
                                        size: 24,
                                        color: Color.lerp(
                                          dark
                                              ? Colors.white60
                                              : AppColors.textSecondary,
                                          dark
                                              ? Colors.white
                                              : AppColors.brandPrimaryDark,
                                          influence,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
