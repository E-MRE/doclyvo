/// Where a watermark sits on the page.
enum PdfWatermarkPlacement {
  center,
  tiled,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Settings for the Watermark tool.
final class PdfWatermarkOptions {
  const PdfWatermarkOptions({
    this.text = '',
    this.placement = PdfWatermarkPlacement.center,
    this.opacity = 0.3,
    this.rotation = 45,
    this.fontSize = 48,
    this.behindContent = false,
    this.pageIndexes,
  });

  /// The watermark text itself.
  final String text;

  /// Position preset on the page.
  final PdfWatermarkPlacement placement;

  /// Opacity between `0` (invisible) and `1` (opaque).
  final double opacity;

  /// Clockwise text rotation in degrees.
  final double rotation;

  /// Font size in PDF points.
  final double fontSize;

  /// Whether the watermark is drawn under the page content instead of over it.
  final bool behindContent;

  /// Pages to stamp, or `null` for every page.
  final List<int>? pageIndexes;
}
