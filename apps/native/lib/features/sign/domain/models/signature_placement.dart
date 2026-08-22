import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';

/// Where on the page the signature lands, as fractions of the page box.
///
/// Fractions, not points, for the same reason `apps/web` uses them: the caller
/// does not know the page size, and the design draws the box relative to the
/// page (bottom-right, roughly a third of the width). [y] is measured from the
/// **top** — that is `apps/api`'s convention for the same four numbers, and
/// keeping it identical is what makes native and web place the signature in
/// the same spot. [toStampArea] flips it, because `PdfStampArea.y` is measured
/// from the bottom.
final class SignaturePlacement {
  const SignaturePlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// The design's fixed bottom-right box, byte-identical to `apps/web`'s
  /// `PLACEMENT_BOX`.
  ///
  /// Both the desktop and mobile design exports draw the signature pinned to
  /// the bottom-right of the page with no drag handle, and `apps/web` ships the
  /// same fixed box — so native MVP has no free placement either. Making the
  /// box draggable is a later task, not a hidden branch of this screen.
  static const SignaturePlacement bottomRight = SignaturePlacement(
    x: 0.6,
    y: 0.78,
    width: 0.32,
    height: 0.1,
  );

  /// Distance from the page's left edge, as a fraction of page width.
  final double x;

  /// Distance from the page's **top** edge, as a fraction of page height.
  final double y;

  /// Box width, as a fraction of page width.
  final double width;

  /// Box height, as a fraction of page height.
  final double height;

  /// Converts to the engine's point-based, bottom-left-origin rectangle.
  PdfStampArea toStampArea({
    required double pageWidth,
    required double pageHeight,
  }) {
    final boxWidth = width * pageWidth;
    final boxHeight = height * pageHeight;
    return PdfStampArea(
      x: x * pageWidth,
      y: pageHeight - y * pageHeight - boxHeight,
      width: boxWidth,
      height: boxHeight,
    );
  }
}
