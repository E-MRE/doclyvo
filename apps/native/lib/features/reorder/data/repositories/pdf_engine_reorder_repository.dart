import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/reorder/data/repositories/reorder_repository.dart';

/// [ReorderRepository] backed by the on-device [PdfEngineService] — zero
/// network calls, per the Phase 3A architecture decision.
final class PdfEngineReorderRepository implements ReorderRepository {
  const PdfEngineReorderRepository(this._engine);

  final PdfEngineService _engine;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final info = await _engine.readDocumentInfo(bytes: bytes);
    return info.pageCount;
  }

  @override
  Stream<PdfPageThumbnail> renderThumbnails({required Uint8List bytes}) {
    return _engine.renderThumbnails(bytes: bytes);
  }

  @override
  Future<Uint8List> reorderPages({
    required Uint8List bytes,
    required List<int> pageOrder,
  }) {
    return _engine.reorderPages(bytes: bytes, pageOrder: pageOrder);
  }
}
