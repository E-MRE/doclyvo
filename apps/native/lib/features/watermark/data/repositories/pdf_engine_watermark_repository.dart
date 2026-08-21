import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/watermark/data/repositories/watermark_repository.dart';

/// [WatermarkRepository] backed by the on-device [PdfEngineService] — zero
/// network calls, per the Phase 3A architecture decision.
final class PdfEngineWatermarkRepository implements WatermarkRepository {
  const PdfEngineWatermarkRepository(this._engine);

  final PdfEngineService _engine;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final info = await _engine.readDocumentInfo(bytes: bytes);
    return info.pageCount;
  }

  @override
  Future<PdfPageThumbnail?> renderFirstPageThumbnail({
    required Uint8List bytes,
  }) async {
    final thumbnails = await _engine
        .renderThumbnails(bytes: bytes, pageIndexes: const [0])
        .toList();
    return thumbnails.isEmpty ? null : thumbnails.first;
  }

  @override
  Future<Uint8List> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
  }) {
    return _engine.addWatermark(bytes: bytes, options: options);
  }
}
