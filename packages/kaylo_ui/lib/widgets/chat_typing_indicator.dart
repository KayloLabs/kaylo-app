import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A shared, quiet typing cue. Draft text never leaves the composer.
class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({
    super.key,
    required this.label,
    this.visible = true,
  });
  final String label;
  final bool visible;
  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );
  bool _reduceMotion = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didUpdateWidget(ChatTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (widget.visible &&
        !_reduceMotion &&
        TickerMode.valuesOf(context).enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedSize(
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: !widget.visible
          ? const SizedBox(width: double.infinity)
          : Semantics(
              label: widget.label,
              liveRegion: true,
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _motion,
                        builder: (context, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) {
                            final wave = _reduceMotion
                                ? 0.0
                                : math.sin(
                                    _motion.value * math.pi * 2 - i * .7,
                                  );
                            return Transform.translate(
                              offset: Offset(0, -2 * wave),
                              child: Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.withValues(
                                    alpha: .55 + .25 * wave,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          widget.label,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
