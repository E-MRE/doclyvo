import 'dart:typed_data';

/// Concatenates multiple PDFs into one, in a caller-given order.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as `CompressRepository`/
/// `SplitRepository`) — this is Phase 3A, so the concrete implementation
/// calls `PdfEngineService`, never `NetworkService`.
abstract class MergeRepository {
  /// Page count of the document at [bytes], read without modifying it —
  /// drives `design/Merge.dc.html`'s per-row "{pages} sayfa" and the
  /// "Toplam sayfa" summary.
  Future<int> readPageCount({required Uint8List bytes});

  /// Concatenates [documents] in the given order into one PDF.
  Future<Uint8List> merge({required List<Uint8List> documents});
}
