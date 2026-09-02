import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Apple-style "liquid glass" surface.
///
/// Layers (bottom to top):
///   1. Backdrop blur + saturation boost with a whisper of tint (vibrancy)
///   2. Edge refraction — the backdrop is re-sampled through a magnifying
///      matrix inside a band along the border, so background content is
///      genuinely bent and displaced where the "thick" glass edge would
///      lens it. This is real optical warping of what's behind the surface
///      (the same backdrop-matrix technique Flutter's text magnifier uses),
///      most visible while content scrolls behind the glass.
///   3. Refraction shading gradient (light concentration at the lensed edge)
///   4. Specular rim (sweep gradient + chromatic fringe strokes)
///   5. Pointer-tracking specular highlight (hover / press)
///
/// Passing [onTap] makes the surface interactive: it springs down slightly
/// while pressed and the highlight brightens, like iOS glass buttons.
/// Widgets that wrap their own gesture targets (search bars, nav items)
/// simply omit [onTap] and all pointer events pass through untouched.
class KayloLiquidGlass extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? colorOverlay;
  final VoidCallback? onTap;

  const KayloLiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.width,
    this.height,
    this.colorOverlay,
    this.onTap,
  });

  @override
  State<KayloLiquidGlass> createState() => _KayloLiquidGlassState();
}

class _KayloLiquidGlassState extends State<KayloLiquidGlass> {
  Offset? _pointer;
  bool _hovering = false;
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tintColor = widget.colorOverlay ??
        (isDark
            ? const Color(0xFF16211B).withOpacity(0.15)
            : const Color(0xFFFAF8F3).withOpacity(0.15));

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          // 1. Backdrop blur + saturation boost (vibrancy) + tint. Real glass
          // concentrates color, so the backdrop reads richer through it.
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.compose(
                outer: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                inner: _saturationFilter(isDark ? 1.25 : 1.55),
              ),
              child: Container(color: tintColor),
            ),
          ),

          // 2. Edge refraction: inside a band along the border, re-sample
          // the backdrop through a magnifying matrix anchored at the widget
          // center — background content bends inward at the edge exactly as
          // it would through a convex gel edge.
          Positioned.fill(
            child: IgnorePointer(
              child: ClipPath(
                clipper: _EdgeRingClipper(borderRadius: widget.borderRadius),
                child: const _BackdropRefraction(
                  scale: 1.18,
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),

          // 3. Refraction shading — light concentrates where the edge lenses.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.8),
                    radius: 2.0,
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.05 : 0.26),
                      Colors.white.withOpacity(0.0),
                      Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 5. Pointer-tracking specular highlight
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                opacity: (_hovering || _pressed) ? 1.0 : 0.0,
                child: _pointer == null
                    ? const SizedBox.shrink()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          final align = Alignment(
                            (_pointer!.dx / size.width) * 2 - 1,
                            (_pointer!.dy / size.height) * 2 - 1,
                          );
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: align,
                                radius: 1.1,
                                colors: [
                                  Colors.white.withOpacity(
                                     _pressed
                                        ? (isDark ? 0.14 : 0.42)
                                        : (isDark ? 0.08 : 0.26),
                                  ),
                                  Colors.white.withOpacity(0.0),
                                ],
                                stops: const [0.0, 0.7],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),

          // 4. Specular rim — sweep gradient so light catches the corners
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GlassRimPainter(
                  borderRadius: widget.borderRadius,
                  isDark: isDark,
                  pressed: _pressed,
                ),
              ),
            ),
          ),

          // Content layer (sizes the Stack)
          Container(
            padding: widget.padding,
            child: widget.child,
          ),
        ],
      ),
    );

    Widget result = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: glass,
    );

    // Hover tracking never intercepts events, so it is always safe.
    result = MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onHover: (event) => setState(() => _pointer = event.localPosition),
      onExit: (_) => setState(() {
        _hovering = false;
        _pointer = null;
      }),
      child: result,
    );

    if (widget.onTap != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          _pointer = details.localPosition;
          _setPressed(true);
        },
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.965 : 1.0,
          duration: Duration(milliseconds: _pressed ? 110 : 320),
          curve: _pressed ? Curves.easeOut : Curves.elasticOut,
          child: result,
        ),
      );
    }

    return result;
  }
}

/// Saturation color matrix used to give the blurred backdrop the vibrancy
/// Apple glass has — colors behind the surface come through richer.
ui.ImageFilter _saturationFilter(double s) {
  final sr = (1 - s) * 0.2126;
  final sg = (1 - s) * 0.7152;
  final sb = (1 - s) * 0.0722;
  return ColorFilter.matrix(<double>[
    sr + s, sg, sb, 0, 0,
    sr, sg + s, sb, 0, 0,
    sr, sg, sb + s, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// Re-samples the backdrop through a magnifying matrix anchored at this
/// widget's center — genuine optical warping of the content behind the
/// glass. Same backdrop-matrix technique as Flutter's RawMagnifier; the
/// anchor is computed from the paint offset so it stays correct wherever
/// the widget sits on screen.
class _BackdropRefraction extends SingleChildRenderObjectWidget {
  final double scale;

  const _BackdropRefraction({required this.scale, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBackdropRefraction(scale);

  @override
  void updateRenderObject(
      BuildContext context, _RenderBackdropRefraction renderObject) {
    renderObject.scale = scale;
  }
}

class _RenderBackdropRefraction extends RenderProxyBox {
  _RenderBackdropRefraction(this._scale);

  double _scale;
  set scale(double value) {
    if (_scale == value) return;
    _scale = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final center = offset + Offset(size.width / 2, size.height / 2);
    final matrix = Matrix4.identity()
      ..translate(center.dx, center.dy, 0.0)
      ..scale(_scale, _scale, 1.0)
      ..translate(-center.dx, -center.dy, 0.0);
    context.pushLayer(
      BackdropFilterLayer(
        filter: ui.ImageFilter.matrix(
          matrix.storage,
          filterQuality: FilterQuality.low,
        ),
      ),
      super.paint,
      offset,
    );
  }
}

/// Clips to the band between the outer rounded rect and a deflated inner
/// one — the "thickness" of the glass where refraction is strongest.
class _EdgeRingClipper extends CustomClipper<Path> {
  final double borderRadius;

  _EdgeRingClipper({required this.borderRadius});

  @override
  Path getClip(Size size) {
    final thickness =
        (size.shortestSide * 0.16).clamp(5.0, 16.0).toDouble();
    final outer = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(borderRadius),
      ));
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(thickness),
        Radius.circular((borderRadius - thickness * 0.75).clamp(0.0, 1000.0)),
      ));
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  bool shouldReclip(_EdgeRingClipper oldClipper) =>
      oldClipper.borderRadius != borderRadius;
}

/// Draws the glass rim as a stroked rounded rect with a sweep gradient:
/// bright at the top edge, a soft kick on the lower-left corner, dark
/// falloff at the bottom — the way real glass edges catch ambient light.
class _GlassRimPainter extends CustomPainter {
  final double borderRadius;
  final bool isDark;
  final bool pressed;

  _GlassRimPainter({
    required this.borderRadius,
    required this.isDark,
    required this.pressed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(borderRadius),
    );

    // Kept soft: the bar can sit over dark content (pinned search bar
    // above the hero banner), where a bright rim reads as a white
    // outline instead of a glass edge.
    final boost = pressed ? 1.5 : 1.0;
    final top = (isDark ? 0.20 : 0.38) * boost;
    final side = (isDark ? 0.06 : 0.11) * boost;
    final bottom = isDark ? 0.02 : 0.04;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: const GradientRotation(-math.pi / 2),
        colors: [
          Colors.white.withOpacity(top.clamp(0.0, 1.0)),
          Colors.white.withOpacity(side),
          Colors.white.withOpacity(bottom),
          Colors.white.withOpacity(side * 1.4),
          Colors.white.withOpacity(bottom),
          Colors.white.withOpacity(side),
          Colors.white.withOpacity(top.clamp(0.0, 1.0)),
        ],
        stops: const [0.0, 0.2, 0.42, 0.5, 0.58, 0.8, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);

    // Chromatic fringe: real glass edges split light — a cool cast on the
    // top-left rim, a warm one on the bottom-right, both barely-there.
    final fringeAlpha = isDark ? 0.05 : 0.10;
    final cool = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF7FD4FF).withOpacity(fringeAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(1.0), cool);

    final warm = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          const Color(0xFFFFB27F).withOpacity(fringeAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect);
    canvas.drawRRect(rrect.deflate(1.0), warm);
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.pressed != pressed ||
      oldDelegate.borderRadius != borderRadius;
}
