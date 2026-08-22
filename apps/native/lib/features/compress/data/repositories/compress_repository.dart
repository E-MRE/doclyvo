import 'dart:typed_data';

import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';

/// Compresses a PDF at a chosen [CompressQuality] preset.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as a network repository) — this is
/// Phase 3A, so the concrete implementation calls `PdfEngineService`, never
/// `NetworkService`.
///
/// The returned bytes are never larger than the input: an implementation that
/// cannot actually shrink the document returns the original, and the caller
/// detects that by comparing lengths. Compression is best-effort by nature —
/// there is no reduction to promise up front (see [CompressQuality]).
abstract class CompressRepository {
  Future<Uint8List> compress({
    required Uint8List bytes,
    required CompressQuality quality,
  });
}
