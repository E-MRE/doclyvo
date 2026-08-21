import 'dart:typed_data';

/// The outcome of splitting a PDF into one file per page.
///
/// `design/Split.dc.html` downloads a single `.zip`, not N loose files, so the
/// repository assembles the archive (see the P0-11 Decisions log entry:
/// `PdfEngineService.split` hands back individual files, never a zip —
/// bundling them is the feature's job). Only [pageCount] and [zipBytes] are
/// kept; there is no meaningful before/after size to show (splitting doesn't
/// shrink or grow the source content the way Compress does).
final class SplitResult {
  const SplitResult({required this.zipBytes, required this.pageCount});

  /// The zip archive containing one PDF per page, in document order.
  final Uint8List zipBytes;

  /// Number of pages the source document had, and the number of PDFs inside
  /// [zipBytes].
  final int pageCount;
}
