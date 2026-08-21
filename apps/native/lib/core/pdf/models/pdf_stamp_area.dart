/// A rectangle on a PDF page, in PDF points with the origin at the page's
/// bottom-left corner.
///
/// Used to place an image stamp (Sign) or mark a region.
final class PdfStampArea {
  const PdfStampArea({
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
  });

  /// Distance from the page's left edge, in points.
  final double x;

  /// Distance from the page's bottom edge, in points.
  final double y;

  /// Width of the rectangle, in points.
  final double width;

  /// Height of the rectangle, in points.
  final double height;
}
