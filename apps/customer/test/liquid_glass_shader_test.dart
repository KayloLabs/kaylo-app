import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

// This exercises GLSL sampling using Skia's Canvas shader API. Engine-provided
// backdrop uniforms are supplied explicitly, so this is not a native Impeller
// backdrop integration test.
void main() {
  testWidgets('glass refracts the selected lens at an offset and device scale', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/navigation_glass.frag',
      );
      for (final scale in [1.0, 2.0]) {
        final width = (440 * scale).round();
        final height = (800 * scale).round();
        final origin = ui.Offset(50 * scale, 650 * scale);
        final shiftedOrigin = origin - ui.Offset(0, 60 * scale);
        final background = await _background(width, height, scale);
        final original = (await background.toByteData())!;
        final first = await _render(
          program,
          background,
          origin,
          scale,
          position: 0,
        );
        final center = await _render(
          program,
          background,
          origin,
          scale,
          position: 2,
        );
        final shifted = await _render(
          program,
          background,
          shiftedOrigin,
          scale,
          position: 2,
        );
        final firstData = (await first.toByteData())!;
        final centerData = (await center.toByteData())!;
        final shiftedData = (await shifted.toByteData())!;

        // Moving the lens must move the refracted image, not just its outline.
        final firstLens = ui.Rect.fromLTWH(
          origin.dx + 15 * scale,
          origin.dy + 13 * scale,
          52 * scale,
          40 * scale,
        );
        final centerLens = ui.Rect.fromLTWH(
          origin.dx + 145 * scale,
          origin.dy + 13 * scale,
          52 * scale,
          40 * scale,
        );
        expect(
          _difference(firstData, original, width, firstLens),
          greaterThan(2),
        );
        expect(
          _difference(firstData, centerData, width, firstLens),
          greaterThan(2),
        );
        expect(
          _difference(firstData, centerData, width, centerLens),
          greaterThan(2),
        );

        // Outside either selected lens, the center of the rail stays clear.
        final clear = ui.Rect.fromLTWH(
          origin.dx + 295 * scale,
          origin.dy + 28 * scale,
          2 * scale,
          8 * scale,
        );
        expect(_difference(centerData, original, width, clear), lessThan(2));
        expect(_difference(firstData, centerData, width, clear), lessThan(.1));

        // A translated parent must move the refraction with the capsule.
        // The stripe input repeats vertically, so the translated result matches.
        expect(
          _difference(
            centerData,
            shiftedData,
            width,
            centerLens,
            secondOffset: ui.Offset(0, -60 * scale),
          ),
          lessThan(.6),
        );
        final capturePath = Platform.environment['KAYLO_GLASS_CAPTURE'];
        if (scale == 1 && capturePath != null) {
          final png = await center.toByteData(format: ui.ImageByteFormat.png);
          await File(capturePath).writeAsBytes(png!.buffer.asUint8List());
        }
        first.dispose();
        center.dispose();
        shifted.dispose();
        background.dispose();
      }
    });
  });
}

Future<ui.Image> _background(int width, int height, double scale) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawPaint(ui.Paint()..color = const ui.Color(0xFFF4F0DF));
  final colors = [
    const ui.Color(0xFF386C56),
    const ui.Color(0xFFCA956E),
    const ui.Color(0xFF709BBC),
  ];
  // Narrow colored stripes expose small displacements. x=345..347 lies in
  // a clear interval, deliberately away from both lenses and the rail's rim.
  for (var x = 0; x < width; x += (12 * scale).round()) {
    canvas.drawRect(
      ui.Rect.fromLTWH(x.toDouble(), 0, 3 * scale, height.toDouble()),
      ui.Paint()..color = colors[(x / (12 * scale)).round() % colors.length],
    );
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

Future<ui.Image> _render(
  ui.FragmentProgram program,
  ui.Image input,
  ui.Offset origin,
  double scale, {
  required double position,
}) async {
  final shader = program.fragmentShader();
  final values = [
    input.width.toDouble(),
    input.height.toDouble(),
    origin.dx,
    origin.dy,
    scale,
    scale,
    340.0,
    66.0,
    position,
    .06,
    .6,
  ];
  for (var i = 0; i < values.length; i++) {
    shader.setFloat(i, values[i]);
  }
  shader.setImageSampler(0, input);
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImage(input, ui.Offset.zero, ui.Paint());
  final rect = origin & ui.Size(340 * scale, 66 * scale);
  canvas.clipRRect(
    ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(33 * scale)),
  );
  // Retain scene coordinates; the shader receives the same explicit origin.
  canvas.drawRect(rect, ui.Paint()..shader = shader);
  final picture = recorder.endRecording();
  final image = await picture.toImage(input.width, input.height);
  picture.dispose();
  shader.dispose();
  return image;
}

double _difference(
  ByteData first,
  ByteData second,
  int width,
  ui.Rect region, {
  ui.Offset secondOffset = ui.Offset.zero,
}) {
  var difference = 0.0;
  var count = 0;
  for (var y = region.top.ceil(); y < region.bottom.floor(); y++) {
    for (var x = region.left.ceil(); x < region.right.floor(); x++) {
      final a = (y * width + x) * 4;
      final b =
          ((y + secondOffset.dy.round()) * width +
              x +
              secondOffset.dx.round()) *
          4;
      for (var channel = 0; channel < 3; channel++) {
        difference +=
            (first.getUint8(a + channel) - second.getUint8(b + channel)).abs();
        count++;
      }
    }
  }
  return difference / count;
}
