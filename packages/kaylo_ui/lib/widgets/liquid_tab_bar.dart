import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'liquid_nav_surface.dart';

/// One continuous lens. Dragging previews a destination; release commits it.
/// A cancelled gesture returns to the current tab without navigating.
class LiquidTabBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onSelected;
  final List<String> labels;
  final List<IconData> icons;
  final List<IconData> selectedIcons;
  final List<int> badgeCounts;
  const LiquidTabBar({
    super.key,
    required this.index,
    required this.onSelected,
    required this.labels,
    this.icons = const [
      Icons.home_outlined,
      Icons.calendar_today_outlined,
      Icons.favorite_outline,
      Icons.chat_bubble_outline,
      Icons.person_outline,
    ],
    this.selectedIcons = const [
      Icons.home_rounded,
      Icons.calendar_today_rounded,
      Icons.favorite_rounded,
      Icons.chat_bubble_rounded,
      Icons.person_rounded,
    ],
    this.badgeCounts = const [],
  }) : assert(labels.length >= 2),
       assert(labels.length == icons.length),
       assert(labels.length == selectedIcons.length),
       assert(badgeCounts.length == 0 || badgeCounts.length == labels.length);
  @override
  State<LiquidTabBar> createState() => _LiquidTabBarState();
}

class _LiquidTabBarState extends State<LiquidTabBar>
    with TickerProviderStateMixin {
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.index.toDouble(),
  );
  late final _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
    reverseDuration: const Duration(milliseconds: 260),
  );
  final _clock = Stopwatch()..start();
  int? _lastDragTime;
  double _dragVelocity = 0;
  bool _dragging = false;
  int? _preview;

  bool get _reduce => MediaQuery.disableAnimationsOf(context);
  void _settle(double target, {double? velocity}) {
    if (_reduce) {
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
  void didUpdateWidget(LiquidTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !_dragging) {
      _settle(widget.index.toDouble());
    }
  }

  void _drag(double x, double width, bool rtl) {
    final logical = rtl ? width * widget.labels.length - x : x;
    final position = (logical / width - .5).clamp(
      0.0,
      (widget.labels.length - 1).toDouble(),
    );
    final next = (logical / width).floor().clamp(0, widget.labels.length - 1);
    final now = _clock.elapsedMicroseconds;
    if (_lastDragTime != null) {
      final seconds = (now - _lastDragTime!) / 1000000;
      if (seconds > .001) {
        _dragVelocity =
            ((_dragVelocity * .4) + (position - _position.value) / seconds * .6)
                .clamp(-10.0, 10.0);
      }
    }
    _lastDragTime = now;
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
    _settle(next.toDouble(), velocity: cancel ? 0 : _dragVelocity);
    _lastDragTime = null;
    _dragVelocity = 0;
    if (!cancel && next != widget.index) widget.onSelected(next);
  }

  @override
  void dispose() {
    _press.dispose();
    _clock.stop();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 14) / widget.labels.length;
        return Listener(
          onPointerDown: (_) {
            if (!_reduce) _press.forward();
          },
          onPointerUp: (_) => _press.reverse(),
          onPointerCancel: (_) {
            _press.reverse();
            _end(cancel: true);
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_position, _press]),
            builder: (context, _) {
              final p = _position.value.clamp(
                0.0,
                (widget.labels.length - 1).toDouble(),
              );
              final physical = rtl ? widget.labels.length - 1 - p : p;
              final speed = _dragging ? _dragVelocity : _position.velocity;
              final stretch = _reduce ? 0.0 : math.min(.15, speed.abs() * .016);
              return LiquidNavSurface(
                count: widget.labels.length,
                position: physical,
                stretch: stretch,
                press: _reduce
                    ? 0
                    : Curves.easeOutCubic.transform(_press.value),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (d) =>
                        _drag(d.localPosition.dx, width, rtl),
                    onHorizontalDragUpdate: (d) =>
                        _drag(d.localPosition.dx, width, rtl),
                    onHorizontalDragEnd: (_) => _end(),
                    onHorizontalDragCancel: () => _end(cancel: true),
                    onLongPressStart: (d) =>
                        _drag(d.localPosition.dx, width, rtl),
                    onLongPressMoveUpdate: (d) =>
                        _drag(d.localPosition.dx, width, rtl),
                    onLongPressEnd: (_) => _end(),
                    onLongPressCancel: () => _end(cancel: true),
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: List.generate(widget.labels.length, (i) {
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
                                      child: Badge.count(
                                        count: widget.badgeCounts.isEmpty
                                            ? 0
                                            : widget.badgeCounts[i],
                                        isLabelVisible:
                                            widget.badgeCounts.isNotEmpty &&
                                            widget.badgeCounts[i] > 0,
                                        child: Icon(
                                          selected
                                              ? widget.selectedIcons[i]
                                              : widget.icons[i],
                                          size: 24,
                                          color: Color.lerp(
                                            dark
                                                ? Colors.white70
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
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
