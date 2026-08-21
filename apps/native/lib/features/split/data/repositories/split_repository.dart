import 'dart:typed_data';

import 'package:doclyvo/features/split/domain/models/split_result.dart';

/// Splits a PDF into one file per page, zipped into a single archive.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as `CompressRepository`) — this is
/// Phase 3A, so the concrete implementation calls `PdfEngineService`, never
/// `NetworkService`.
abstract class SplitRepository {
  /// Page count of the document at [bytes], read without modifying it —
  /// drives `design/Split.dc.html`'s "18 sayfa" idle-state summary.
  Future<int> readPageCount({required Uint8List bytes});

  Future<SplitResult> split({required Uint8List bytes});
}
