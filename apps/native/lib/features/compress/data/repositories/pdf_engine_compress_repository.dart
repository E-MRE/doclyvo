import 'dart:typed_data';

import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/compress/data/repositories/compress_repository.dart';
import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';

/// [CompressRepository] backed by the on-device [PdfEngineService] — zero
/// network calls, per the Phase 3A architecture decision.
final class PdfEngineCompressRepository implements CompressRepository {
  const PdfEngineCompressRepository(this._engine);

  final PdfEngineService _engine;

  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    required CompressQuality quality,
  }) {
    return _engine.compress(bytes: bytes, imageQuality: quality.imageQuality);
  }
}
