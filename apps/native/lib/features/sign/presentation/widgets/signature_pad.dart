import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/sign/domain/services/signature_image_renderer.dart';
import 'package:flutter/material.dart';

/// The design's "Çiz" pad: a bordered box the user signs in with a finger,
/// stylus or trackpad.
///
/// The strokes themselves are owned by the caller, not this widget: the screen
/// has to rasterize them when "Belgeye Yerleştir" is tapped, and a widget that
/// hid them would force a `GlobalKey` round-trip to get them back. Each
/// change reports the pad's current size alongside the strokes, since the
/// rasterizer needs the coordinate space they were captured in.
final class SignaturePad extends StatelessWidget {
  const SignaturePad({
    required this.strokes,
    required this.onStrokesChanged,
    this.enabled = true,
    this.tier = ScreenTier.desktop,
    super.key,
  });

  /// One list of points per pen-down/pen-up pair, in this pad's coordinates.
  final List<List<Offset>> strokes;

  /// Fires on every point added, with the pad's live size.
  final void Function(List<List<Offset>> strokes, Size canvasSize)
  onStrokesChanged;

  /// When `false`, drawing is ignored (e.g. while the tool is processing).
  final bool enabled;

  final ScreenTier tier;

  /// 140px on desktop/tablet, the mobile design's 110px on mobile.
  double get _height => tier == ScreenTier.mobile ? 110 : 140;

  void _startStroke(Offset point, Size size) {
    onStrokesChanged([
      ...strokes,
      [point],
    ], size);
  }

  void _extendStroke(Offset point, Size size) {
    if (strokes.isEmpty) return _startStroke(point, size);
    onStrokesChanged([
      ...strokes.take(strokes.length - 1),
      [...strokes.last, point],
    ], size);
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          border: Border.all(color: context.surfaceBorderColor),
        ),
        child: Builder(
          // The pad's own render box is the coordinate space the strokes are
          // captured in; reading it from the gesture's context avoids a
          // LayoutBuilder, which cannot be measured inside the desktop
          // layout's IntrinsicHeight row.
          builder: (padContext) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: enabled
                ? (details) => _startStroke(
                    details.localPosition,
                    padContext.size ?? Size.zero,
                  )
                : null,
            onPanUpdate: enabled
                ? (details) => _extendStroke(
                    details.localPosition,
                    padContext.size ?? Size.zero,
                  )
                : null,
            child: CustomPaint(
              painter: _SignaturePainter(strokes: strokes, color: ink),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

final class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    SignatureImageRenderer.paintStrokes(
      canvas: canvas,
      strokes: strokes,
      color: color,
    );
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.color != color;
}
