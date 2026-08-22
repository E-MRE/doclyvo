// Covers SignatureImageRenderer: both modes must hand PdfEngineService PNG
// bytes, renderStrokes must honour pixelRatio in the bitmap it produces, and a
// single-point stroke must still leave ink (a dotted signature loses its dots
// otherwise).
//
// Every rasterizing call sits inside `tester.runAsync`. Encoding a picture to
// PNG goes through the engine's own task runner, which `flutter_test`'s fake
// async clock never pumps — so `Picture.toImage`/`Image.toByteData` simply
// never complete on the fake clock and the test hangs until the harness kills
// it. `runAsync` puts the call on the real event loop, the same reason
// `test/helpers/widget_test_harness.dart` wraps its translation load in one.
// This is a test-harness constraint, not a defect in the renderer.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doclyvo/features/sign/domain/services/signature_image_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// PNG signature: 0x89 'P' 'N' 'G'.
const _pngMagic = [0x89, 0x50, 0x4E, 0x47];

const _renderer = SignatureImageRenderer();
const _canvasSize = Size(120, 60);
const _ink = Color(0xFF101828);

void _expectPng(Uint8List bytes) {
  expect(bytes.length, greaterThan(_pngMagic.length));
  expect(bytes.sublist(0, _pngMagic.length), _pngMagic);
}

/// Decodes [bytes] so the tests can assert on the real bitmap the renderer
/// produced instead of trusting the requested size.
Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Whether any pixel of [image] is at least partly opaque.
Future<bool> _hasInk(ui.Image image) async {
  final data = await image.toByteData();
  final pixels = data!.buffer.asUint8List();
  for (var i = 3; i < pixels.length; i += 4) {
    if (pixels[i] != 0) return true;
  }
  return false;
}

void main() {
  testWidgets('renderStrokes returns PNG bytes', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderStrokes(
        strokes: const [
          [Offset(10, 10), Offset(40, 30), Offset(90, 20)],
        ],
        canvasSize: _canvasSize,
        color: _ink,
      );

      _expectPng(bytes);
    });
  });

  testWidgets('renderStrokes scales the bitmap by pixelRatio', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderStrokes(
        strokes: const [
          [Offset.zero, Offset(120, 60)],
        ],
        canvasSize: _canvasSize,
        color: _ink,
      );

      final image = await _decode(bytes);
      addTearDown(image.dispose);

      expect(
        image.width,
        (_canvasSize.width * SignatureImageRenderer.pixelRatio).ceil(),
      );
      expect(
        image.height,
        (_canvasSize.height * SignatureImageRenderer.pixelRatio).ceil(),
      );
    });
  });

  testWidgets('renderStrokes draws ink for a multi-point stroke', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderStrokes(
        strokes: const [
          [Offset(5, 5), Offset(60, 30), Offset(115, 55)],
        ],
        canvasSize: _canvasSize,
        color: _ink,
      );

      final image = await _decode(bytes);
      addTearDown(image.dispose);

      expect(await _hasInk(image), isTrue);
    });
  });

  testWidgets('a single-point stroke still produces ink', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderStrokes(
        strokes: const [
          [Offset(60, 30)],
        ],
        canvasSize: _canvasSize,
        color: _ink,
      );

      final image = await _decode(bytes);
      addTearDown(image.dispose);

      expect(await _hasInk(image), isTrue);
    });
  });

  testWidgets('an empty stroke list produces a transparent bitmap', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderStrokes(
        strokes: const [],
        canvasSize: _canvasSize,
        color: _ink,
      );

      _expectPng(bytes);
      final image = await _decode(bytes);
      addTearDown(image.dispose);

      expect(await _hasInk(image), isFalse);
    });
  });

  testWidgets('a stroke with no points is skipped without throwing', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderStrokes(
        strokes: const [
          <Offset>[],
          [Offset(20, 20), Offset(80, 40)],
        ],
        canvasSize: _canvasSize,
        color: _ink,
      );

      final image = await _decode(bytes);
      addTearDown(image.dispose);

      expect(await _hasInk(image), isTrue);
    });
  });

  testWidgets('renderText returns PNG bytes with ink', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderText(
        text: 'Emre Gultekir',
        color: _ink,
      );

      _expectPng(bytes);
      final image = await _decode(bytes);
      addTearDown(image.dispose);

      expect(await _hasInk(image), isTrue);
    });
  });

  testWidgets('renderText keeps typedPadding around the glyphs', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderText(text: 'A', color: _ink);

      final image = await _decode(bytes);
      addTearDown(image.dispose);

      // The bitmap is the laid-out text plus the padding on both sides, so it
      // is strictly wider and taller than twice the padding.
      const minEdge = SignatureImageRenderer.typedPadding * 2;
      expect(image.width, greaterThan(minEdge));
      expect(image.height, greaterThan(minEdge));
    });
  });

  testWidgets('a longer typed name renders a wider bitmap', (tester) async {
    await tester.runAsync(() async {
      final short = await _decode(
        await _renderer.renderText(text: 'A', color: _ink),
      );
      final long = await _decode(
        await _renderer.renderText(text: 'AAAAAAAAAA', color: _ink),
      );
      addTearDown(short.dispose);
      addTearDown(long.dispose);

      expect(long.width, greaterThan(short.width));
    });
  });

  testWidgets('empty typed text still returns valid PNG bytes', (tester) async {
    await tester.runAsync(() async {
      final bytes = await _renderer.renderText(text: '', color: _ink);

      _expectPng(bytes);
      final image = await _decode(bytes);
      addTearDown(image.dispose);

      expect(await _hasInk(image), isFalse);
    });
  });

  testWidgets('paintStrokes draws onto a caller-owned canvas', (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      SignatureImageRenderer.paintStrokes(
        canvas: Canvas(recorder),
        strokes: const [
          [Offset.zero, Offset(30, 30)],
        ],
        color: _ink,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(40, 40);
      addTearDown(image.dispose);
      addTearDown(picture.dispose);

      expect(await _hasInk(image), isTrue);
    });
  });

  test('the rendering constants match the values the pad and stamp share', () {
    expect(SignatureImageRenderer.pixelRatio, 3);
    expect(SignatureImageRenderer.strokeWidth, 3);
    expect(SignatureImageRenderer.typedFontSize, 96);
    expect(SignatureImageRenderer.typedPadding, 24);
  });
}
