import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A single optical surface: the rail and moving lens refract the same backdrop.
/// Native Impeller uses a signed-distance shader; browsers use matrix lenses.
/// The icons stay above the filter, so labels and hit targets remain crisp.
class LiquidNavSurface extends StatefulWidget {
  const LiquidNavSurface({
    super.key,
    required this.position,
    required this.stretch,
    required this.press,
    required this.child,
  });

  final double position;
  final double stretch;
  final double press;
  final Widget child;

  @override
  State<LiquidNavSurface> createState() => _LiquidNavSurfaceState();
}

class _LiquidNavSurfaceState extends State<LiquidNavSurface> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    if (ui.ImageFilter.isShaderFilterSupported) _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await (_program ??= ui.FragmentProgram.fromAsset(
        'shaders/navigation_glass.frag',
      ));
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (error) {
      // Keep a usable, frosted navigation surface if a driver or asset fails.
      _program = null;
      debugPrint('Navigation glass fallback: $error');
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final contrast = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .25 : .09),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .18 : .035),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: Stack(
          children: [
            if (!contrast)
              Positioned.fill(
                child: IgnorePointer(
                  child: _shader != null
                      ? _RefractingBackdrop(
                          shader: _shader!,
                          pixelRatio: View.of(context).devicePixelRatio,
                          position: widget.position,
                          stretch: widget.stretch,
                          press: widget.press,
                        )
                      : _FallbackBackdrop(
                          position: widget.position,
                          stretch: widget.stretch,
                          press: widget.press,
                        ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GlassFinish(
                    position: widget.position,
                    stretch: widget.stretch,
                    press: widget.press,
                    dark: dark,
                    contrast: contrast,
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

Rect _lensRect(Size size, double position, double stretch, double press) {
  final cell = (size.width - 14) / 5;
  return Rect.fromCenter(
    center: Offset(7 + cell * (position + .5), size.height / 2),
    width: cell * (1 + stretch) * (1 + press * .07),
    height: 50 * (1 - stretch * .3) * (1 + press * .07),
  );
}

class _RefractingBackdrop extends LeafRenderObjectWidget {
  const _RefractingBackdrop({
    required this.shader,
    required this.pixelRatio,
    required this.position,
    required this.stretch,
    required this.press,
  });
  final ui.FragmentShader shader;
  final double pixelRatio;
  final double position;
  final double stretch;
  final double press;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRefraction(this);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderRefraction renderObject,
  ) {
    renderObject.settings = this;
    renderObject.markNeedsPaint();
  }
}

class _RenderRefraction extends RenderBox {
  _RenderRefraction(this.settings);
  _RefractingBackdrop settings;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performLayout() => size = constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final transform = getTransformTo(null);
    final origin = MatrixUtils.transformPoint(transform, Offset.zero);
    final sx =
        MatrixUtils.transformPoint(transform, const Offset(1, 0)) - origin;
    final sy =
        MatrixUtils.transformPoint(transform, const Offset(0, 1)) - origin;
    final ratio = settings.pixelRatio;
    final shader = settings.shader;
    // Snapshot coordinates are physical scene pixels, not widget-local pixels.
    // Measuring at paint also follows the enclosing navbar's slide transition.
    shader
      ..setFloat(2, origin.dx * ratio)
      ..setFloat(3, origin.dy * ratio)
      ..setFloat(4, sx.distance * ratio)
      ..setFloat(5, sy.distance * ratio)
      ..setFloat(6, size.width)
      ..setFloat(7, size.height)
      ..setFloat(8, settings.position)
      ..setFloat(9, settings.stretch)
      ..setFloat(10, settings.press);
    context.pushLayer(
      BackdropFilterLayer(filter: ui.ImageFilter.shader(shader)),
      (_, _) {},
      offset,
    );
  }
}

class _FallbackBackdrop extends StatelessWidget {
  const _FallbackBackdrop({
    required this.position,
    required this.stretch,
    required this.press,
  });
  final double position;
  final double stretch;
  final double press;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final lens = _lensRect(constraints.biggest, position, stretch, press);
      return Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: const SizedBox.expand(),
            ),
          ),
          if (kIsWeb)
            Positioned.fromRect(
              rect: lens,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(lens.height / 2),
                child: _MatrixLens(scale: 1.12 + press * .08),
              ),
            ),
        ],
      );
    },
  );
}

class _MatrixLens extends LeafRenderObjectWidget {
  const _MatrixLens({required this.scale});
  final double scale;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMatrixLens(scale);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMatrixLens renderObject,
  ) {
    renderObject.scale = scale;
    renderObject.markNeedsPaint();
  }
}

class _RenderMatrixLens extends RenderBox {
  _RenderMatrixLens(this.scale);
  double scale;
  @override
  bool get alwaysNeedsCompositing => true;
  @override
  void performLayout() => size = constraints.biggest;
  @override
  void paint(PaintingContext context, Offset offset) {
    final center = offset + size.center(Offset.zero);
    final matrix = Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
    context.pushLayer(
      BackdropFilterLayer(
        filter: ui.ImageFilter.matrix(
          matrix.storage,
          filterQuality: FilterQuality.medium,
        ),
      ),
      (_, _) {},
      offset,
    );
  }
}

class _GlassFinish extends CustomPainter {
  const _GlassFinish({
    required this.position,
    required this.stretch,
    required this.press,
    required this.dark,
    required this.contrast,
  });
  final double position;
  final double stretch;
  final double press;
  final bool dark;
  final bool contrast;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rail = RRect.fromRectAndRadius(
      rect.deflate(.6),
      const Radius.circular(34),
    );
    final lensRect = _lensRect(size, position, stretch, press);
    final lens = RRect.fromRectAndRadius(
      lensRect,
      Radius.circular(lensRect.height / 2),
    );
    canvas.drawRRect(
      rail,
      Paint()
        ..color = (dark ? const Color(0xFF132219) : const Color(0xFFF7FAF6))
            .withValues(alpha: contrast ? 1 : (dark ? .55 : .36)),
    );
    if (contrast) {
      canvas.drawRRect(
        lens,
        Paint()
          ..color = dark ? const Color(0xFF42674B) : const Color(0xFFD9ECDD),
      );
      canvas.drawRRect(
        lens,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = dark ? Colors.white : const Color(0xFF235139),
      );
      return;
    }
    // Opposing highlights and a dark lower seam give the rim thickness.
    canvas.drawRRect(
      rail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xCFFFFFFF),
            Color(0x20FFFFFF),
            Color(0x300D2818),
            Color(0x99FFFFFF),
          ],
          stops: [0, .35, .7, 1],
        ).createShader(rect),
    );
    canvas.drawRRect(
      lens,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-.8 + position * .4, -1),
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: (dark ? .18 : .55) - press * .12),
            const Color(0xFF2F7A4F).withValues(alpha: .13 - press * .07),
            Colors.white.withValues(alpha: dark ? .09 : .26),
          ],
          stops: const [0, .56, 1],
        ).createShader(lensRect),
    );
    canvas.drawRRect(
      lens.deflate(.65),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + press * .25
        ..shader = SweepGradient(
          transform: GradientRotation(-math.pi * .65 + position * .12),
          colors: [
            Colors.white.withValues(alpha: dark ? .65 : .95),
            Colors.white.withValues(alpha: .08),
            Colors.white.withValues(alpha: dark ? .32 : .72),
            const Color(0xFF183D27).withValues(alpha: .11),
            Colors.white.withValues(alpha: dark ? .65 : .95),
          ],
          stops: const [0, .3, .53, .76, 1],
        ).createShader(lensRect),
    );
    canvas.drawRRect(
      lens.deflate(2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFA1DCD8).withValues(alpha: .25),
            Colors.transparent,
            const Color(0xFFEED7AF).withValues(alpha: .28),
          ],
        ).createShader(lensRect),
    );
  }

  @override
  bool shouldRepaint(_GlassFinish oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.stretch != stretch ||
      oldDelegate.press != press ||
      oldDelegate.dark != dark ||
      oldDelegate.contrast != contrast;
}
