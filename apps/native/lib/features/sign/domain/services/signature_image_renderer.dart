import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Turns whatever the user produced — freehand strokes or a typed name — into
/// the PNG bytes `PdfEngineService.addImageStamp` needs.
///
/// This exists because `pdf_manipulator` has exactly one stamping primitive
/// and it takes an image: unlike `apps/api`'s reportlab overlay, there is no
/// "draw this text into the PDF" path, so the typed mode has to rasterize
/// on-device. Doing it here rather than in a widget keeps it out of a build
/// method and makes both modes unit-testable without pumping a screen.
final class SignatureImageRenderer {
  const SignatureImageRenderer();

  /// Pixel size of the rendered strokes' longest edge target multiplier.
  ///
  /// The pad is laid out in logical pixels but the stamp is scaled into a
  /// PDF box, so rendering at 3x keeps the ink crisp when the box is wider
  /// than the pad was.
  static const double pixelRatio = 3;

  /// Stroke width used both on the pad and in the rasterized output.
  static const double strokeWidth = 3;

  /// Font size the typed name is rendered at before being scaled into the
  /// stamp box.
  static const double typedFontSize = 96;

  /// Transparent padding kept around the typed name, in rendered pixels, so
  /// the glyphs' descenders are not clipped by the bitmap edge.
  static const double typedPadding = 24;

  /// Rasterizes freehand [strokes] captured over a [canvasSize] area.
  ///
  /// [strokes] is one list of points per pen-down/pen-up pair, in the pad's
  /// local coordinates. Returns transparent-background PNG bytes.
  Future<Uint8List> renderStrokes({
    required List<List<Offset>> strokes,
    required Size canvasSize,
    required Color color,
  }) {
    return _record(
      size: Size(
        canvasSize.width * pixelRatio,
        canvasSize.height * pixelRatio,
      ),
      paint: (canvas) {
        canvas.scale(pixelRatio);
        paintStrokes(canvas: canvas, strokes: strokes, color: color);
      },
    );
  }

  /// Rasterizes [text] as a signature graphic.
  ///
  /// Italic rather than a script font: no signature typeface ships with the
  /// app yet (see the P3A-8 Decisions log entry), and italicizing the system
  /// face reads as a signature without adding a font binary.
  Future<Uint8List> renderText({
    required String text,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: typedFontSize,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return _record(
      size: Size(
        painter.width + typedPadding * 2,
        painter.height + typedPadding * 2,
      ),
      paint: (canvas) => painter.paint(
        canvas,
        const Offset(typedPadding, typedPadding),
      ),
    );
  }

  /// Draws [strokes] onto [canvas] with the pad's own pen settings.
  ///
  /// Shared with the on-screen pad's painter so what the user drew and what
  /// gets stamped cannot drift apart.
  static void paintStrokes({
    required Canvas canvas,
    required List<List<Offset>> strokes,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        // A tap with no drag still has to leave a mark, otherwise a dotted
        // signature loses its dots.
        canvas.drawPoints(ui.PointMode.points, stroke, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  Future<Uint8List> _record({
    required Size size,
    required void Function(Canvas canvas) paint,
  }) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder));
    final picture = recorder.endRecording();

    // `ceil` because toImage takes whole pixels and rounding down would clip
    // the last column/row of ink.
    final image = await picture.toImage(
      size.width.ceil(),
      size.height.ceil(),
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}
