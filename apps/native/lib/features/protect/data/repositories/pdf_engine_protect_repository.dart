import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/protect/data/repositories/protect_repository.dart';

/// [ProtectRepository] backed by the on-device [PdfEngineService] — zero
/// network calls, per the Phase 3A architecture decision.
final class PdfEngineProtectRepository implements ProtectRepository {
  const PdfEngineProtectRepository(this._engine);

  final PdfEngineService _engine;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final info = await _engine.readDocumentInfo(bytes: bytes);
    return info.pageCount;
  }

  @override
  Future<Uint8List> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
  }) {
    return _engine.protect(bytes: bytes, options: options);
  }
}
