import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';

/// Rewrites a PDF with its pages in a caller-given order, and renders page
/// previews to reorder by.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as `RotateRepository`) — this is
/// Phase 3A, so the concrete implementation calls `PdfEngineService`, never
/// `NetworkService`.
abstract class ReorderRepository {
  /// Page count of the document at [bytes], read without modifying it —
  /// drives the grid's initial placeholder-tile count before previews arrive.
  Future<int> readPageCount({required Uint8List bytes});

  /// Streams a preview per page, in whatever order the engine produces them.
  Stream<PdfPageThumbnail> renderThumbnails({required Uint8List bytes});

  /// Rewrites the document with its pages in [pageOrder] (the source page
  /// index for each output position).
  Future<Uint8List> reorderPages({
    required Uint8List bytes,
    required List<int> pageOrder,
  });
}
