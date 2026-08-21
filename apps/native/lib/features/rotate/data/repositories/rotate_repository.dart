import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';

/// Rotates selected pages of a PDF, and renders page previews to select them.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as `MergeRepository`/
/// `SplitRepository`) — this is Phase 3A, so the concrete implementation
/// calls `PdfEngineService`, never `NetworkService`.
abstract class RotateRepository {
  /// Page count of the document at [bytes], read without modifying it —
  /// drives the grid's initial placeholder-tile count before previews arrive.
  Future<int> readPageCount({required Uint8List bytes});

  /// Streams a preview per page, in whatever order the engine produces them.
  Stream<PdfPageThumbnail> renderThumbnails({required Uint8List bytes});

  /// Rotates every page named in [pageRotations] by its mapped clockwise
  /// degrees, leaving unselected pages untouched.
  Future<Uint8List> rotatePages({
    required Uint8List bytes,
    required Map<int, int> pageRotations,
  });
}
