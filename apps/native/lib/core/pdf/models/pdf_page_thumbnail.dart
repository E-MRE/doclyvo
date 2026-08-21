import 'dart:typed_data';

/// A single rendered page preview, produced by
/// `PdfEngineService.renderThumbnails`.
///
/// Used by the tools that need a visual page list (Rotate, Reorder, and the
/// region-marking UI of Redact).
final class PdfPageThumbnail {
  const PdfPageThumbnail({
    required this.pageIndex,
    required this.width,
    required this.height,
    required this.pngBytes,
  });

  /// Zero-based index of the page this preview belongs to.
  final int pageIndex;

  /// Pixel width of the rendered image.
  final int width;

  /// Pixel height of the rendered image.
  final int height;

  /// PNG-encoded image bytes, ready for `Image.memory`.
  final Uint8List pngBytes;
}
