/// Size and orientation of a single page, as reported by the PDF engine.
///
/// Dimensions are in PDF points (1/72 inch).
final class PdfPageDimensions {
  const PdfPageDimensions({
    this.index = 0,
    this.width = 0,
    this.height = 0,
    this.rotation = 0,
  });

  /// Zero-based page index.
  final int index;

  /// Media-box width in points, before [rotation] is applied.
  final double width;

  /// Media-box height in points, before [rotation] is applied.
  final double height;

  /// Clockwise rotation already stored on the page (0, 90, 180 or 270).
  final int rotation;

  /// Width as the page is actually displayed.
  double get effectiveWidth =>
      (rotation == 90 || rotation == 270) ? height : width;

  /// Height as the page is actually displayed.
  double get effectiveHeight =>
      (rotation == 90 || rotation == 270) ? width : height;
}

/// Read-only metadata about a PDF, used to drive tool UIs (page counts for
/// Split, per-page thumbnails for Rotate/Reorder, password prompts for
/// Protect).
final class PdfDocumentInfo {
  const PdfDocumentInfo({
    this.pageCount = 0,
    this.version = '',
    this.pages = const [],
    this.isEncrypted = false,
    this.requiresPassword = false,
  });

  /// Number of pages in the document.
  final int pageCount;

  /// PDF specification version of the document (e.g. `1.7`).
  final String version;

  /// Per-page dimensions, ordered by page index.
  final List<PdfPageDimensions> pages;

  /// Whether the document carries any encryption.
  final bool isEncrypted;

  /// Whether a password is needed before the document can be read.
  final bool requiresPassword;
}
