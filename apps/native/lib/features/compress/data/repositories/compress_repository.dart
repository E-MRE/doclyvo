import 'dart:typed_data';

import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';

/// Compresses a PDF at a chosen [CompressQuality] preset.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as a network repository) — this is
/// Phase 3A, so the concrete implementation calls `PdfEngineService`, never
/// `NetworkService`.
abstract class CompressRepository {
  Future<Uint8List> compress({
    required Uint8List bytes,
    required CompressQuality quality,
  });
}
