import 'dart:typed_data';

import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/merge/data/repositories/merge_repository.dart';

/// [MergeRepository] backed by the on-device [PdfEngineService] — zero
/// network calls, per the Phase 3A architecture decision.
final class PdfEngineMergeRepository implements MergeRepository {
  const PdfEngineMergeRepository(this._engine);

  final PdfEngineService _engine;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final info = await _engine.readDocumentInfo(bytes: bytes);
    return info.pageCount;
  }

  @override
  Future<Uint8List> merge({required List<Uint8List> documents}) {
    return _engine.merge(documents: documents);
  }
}
