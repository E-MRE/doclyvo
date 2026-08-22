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
  }) async {
    final compressed = await _engine.compress(
      bytes: bytes,
      imageQuality: quality.imageQuality,
    );

    // `pdf_manipulator`'s compress re-encodes embedded raster images and then
    // rewrites the file. A PDF that carries little or no image data therefore
    // has nothing to give up, and the rewrite can come back a few bytes
    // *larger* than what went in. Handing that back as "compressed" is how the
    // tool ended up shipping a file it had not shrunk, so the original wins
    // whenever the engine cannot beat it — the screen compares the two sizes
    // and says so plainly.
    return compressed.length < bytes.length ? compressed : bytes;
  }
}
