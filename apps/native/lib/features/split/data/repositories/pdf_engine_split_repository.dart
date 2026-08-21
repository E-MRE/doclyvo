import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/split/data/repositories/split_repository.dart';
import 'package:doclyvo/features/split/domain/models/split_result.dart';

/// [SplitRepository] backed by the on-device [PdfEngineService] — zero
/// network calls, per the Phase 3A architecture decision.
///
/// `PdfEngineService.split` (`pagesPerFile: 1`) returns one PDF per page as a
/// plain `List<Uint8List>`, in document order — no archive, per the P0-11
/// Decisions log entry. `design/Split.dc.html` offers a single "İndir (.zip)"
/// download, so this is where that archive actually gets built, using the
/// `archive` package directly (allowed here: this file sits in `data/`, the
/// same layer `PdfEngineCompressRepository` lives in, and the ban on
/// third-party PDF/file packages is scoped to `pdf_manipulator`/`get_it`/
/// `dio`, not general-purpose archive utilities).
final class PdfEngineSplitRepository implements SplitRepository {
  const PdfEngineSplitRepository(this._engine);

  final PdfEngineService _engine;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final info = await _engine.readDocumentInfo(bytes: bytes);
    return info.pageCount;
  }

  @override
  Future<SplitResult> split({required Uint8List bytes}) async {
    // `pagesPerFile` defaults to 1 — one PDF per page, matching the design's
    // "18 sayfa -> 18 ayrı PDF" copy.
    final pages = await _engine.split(bytes: bytes);
    final zipBytes = _zip(pages);
    return SplitResult(zipBytes: zipBytes, pageCount: pages.length);
  }

  /// Bundles [pages] (one PDF per entry, in document order) into a single
  /// zip archive, naming each entry `sayfa-01.pdf`, `sayfa-02.pdf`, etc., with
  /// enough leading zeros to sort correctly regardless of page count.
  Uint8List _zip(List<Uint8List> pages) {
    final digits = pages.length.toString().length;
    final archive = Archive();
    for (var i = 0; i < pages.length; i++) {
      final pageBytes = pages[i];
      final entryName = 'sayfa-${(i + 1).toString().padLeft(digits, '0')}.pdf';
      archive.addFile(ArchiveFile(entryName, pageBytes.length, pageBytes));
    }
    return ZipEncoder().encodeBytes(archive);
  }
}
