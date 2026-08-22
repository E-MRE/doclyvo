import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/sign/data/repositories/sign_repository.dart';
import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';

/// [SignRepository] backed by the on-device [PdfEngineService] — zero network
/// calls, per the Phase 3A architecture decision.
final class PdfEngineSignRepository implements SignRepository {
  const PdfEngineSignRepository(this._engine);

  final PdfEngineService _engine;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final info = await _engine.readDocumentInfo(bytes: bytes);
    return info.pageCount;
  }

  @override
  Future<Uint8List> sign({
    required Uint8List bytes,
    required Uint8List signatureImageBytes,
    required int pageIndex,
    required SignaturePlacement placement,
  }) async {
    final info = await _engine.readDocumentInfo(bytes: bytes);
    if (pageIndex < 0 || pageIndex >= info.pages.length) {
      throw const PdfEngineException(
        'Signature page is outside the document.',
        kind: PdfEngineErrorKind.pageOutOfRange,
      );
    }

    // `effective*` rather than the raw media box: a page stored with a 90°
    // rotation is displayed sideways, and the user picked the box against
    // what they see.
    final page = info.pages[pageIndex];
    return _engine.addImageStamp(
      bytes: bytes,
      imageBytes: signatureImageBytes,
      pageIndex: pageIndex,
      area: placement.toStampArea(
        pageWidth: page.effectiveWidth,
        pageHeight: page.effectiveHeight,
      ),
    );
  }
}
