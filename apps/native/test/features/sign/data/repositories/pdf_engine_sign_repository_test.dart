// Covers PdfEngineSignRepository: readPageCount forwards the engine's document
// info, sign guards the page index before touching the engine, converts the
// placement against the page's *effective* box (so a stored 90° rotation swaps
// width and height), forwards bytes/imageBytes/pageIndex unchanged, and lets an
// engine exception propagate untouched.

import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/sign/data/repositories/pdf_engine_sign_repository.dart';
import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static Uint8List? lastBytes;
  static Uint8List? lastImageBytes;
  static int? lastPageIndex;
  static PdfStampArea? lastArea;
  static double? lastOpacity;
  static Uint8List stampResult = Uint8List(0);
  static PdfDocumentInfo documentInfo = const PdfDocumentInfo();
  static Exception? stampError;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<PdfDocumentInfo> readDocumentInfo({
    required Uint8List bytes,
    String? password,
  }) async => documentInfo;

  @override
  Future<Uint8List> merge({required List<Uint8List> documents}) =>
      throw UnimplementedError();

  @override
  Future<List<Uint8List>> split({
    required Uint8List bytes,
    int pagesPerFile = 1,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> extractPages({
    required Uint8List bytes,
    required List<int> pageIndexes,
    String? password,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> rotatePages({
    required Uint8List bytes,
    required Map<int, int> pageRotations,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> rotateAllPages({
    required Uint8List bytes,
    required int degrees,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> reorderPages({
    required Uint8List bytes,
    required List<int> pageOrder,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    int imageQuality = 75,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> removeProtection({
    required Uint8List bytes,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Uint8List> addImageStamp({
    required Uint8List bytes,
    required Uint8List imageBytes,
    required int pageIndex,
    required PdfStampArea area,
    double opacity = 1,
  }) async {
    lastBytes = bytes;
    lastImageBytes = imageBytes;
    lastPageIndex = pageIndex;
    lastArea = area;
    lastOpacity = opacity;
    final error = stampError;
    if (error != null) throw error;
    return stampResult;
  }

  @override
  Stream<PdfPageThumbnail> renderThumbnails({
    required Uint8List bytes,
    List<int>? pageIndexes,
    int maxSize = 200,
    String? password,
  }) => throw UnimplementedError();
}

/// A4 in PDF points, matching the parity numbers in the placement test.
const _a4Width = 595.276;
const _a4Height = 841.89;

PdfDocumentInfo _infoWithPages(List<PdfPageDimensions> pages) =>
    PdfDocumentInfo(pageCount: pages.length, pages: pages);

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);
  final imageBytes = Uint8List.fromList([9, 9]);

  setUp(() {
    _FakeEngine.stampError = null;
    _FakeEngine.lastArea = null;
    _FakeEngine.lastOpacity = null;
    _FakeEngine.stampResult = Uint8List.fromList([7, 7, 7]);
    _FakeEngine.documentInfo = _infoWithPages(const [
      PdfPageDimensions(width: _a4Width, height: _a4Height),
      PdfPageDimensions(index: 1, width: _a4Width, height: _a4Height),
      PdfPageDimensions(index: 2, width: _a4Width, height: _a4Height),
    ]);
  });

  test('readPageCount forwards the engine document info page count', () async {
    _FakeEngine.documentInfo = const PdfDocumentInfo(pageCount: 12);
    const repository = PdfEngineSignRepository(_FakeEngine());

    final count = await repository.readPageCount(bytes: bytes);

    expect(count, 12);
  });

  test('sign forwards bytes, image bytes and page index unchanged', () async {
    const repository = PdfEngineSignRepository(_FakeEngine());

    final result = await repository.sign(
      bytes: bytes,
      signatureImageBytes: imageBytes,
      pageIndex: 1,
      placement: SignaturePlacement.bottomRight,
    );

    expect(_FakeEngine.lastBytes, same(bytes));
    expect(_FakeEngine.lastImageBytes, same(imageBytes));
    expect(_FakeEngine.lastPageIndex, 1);
    expect(result, same(_FakeEngine.stampResult));
  });

  test('sign converts the placement against the page box', () async {
    const repository = PdfEngineSignRepository(_FakeEngine());

    await repository.sign(
      bytes: bytes,
      signatureImageBytes: imageBytes,
      pageIndex: 0,
      placement: SignaturePlacement.bottomRight,
    );

    final area = _FakeEngine.lastArea!;
    expect(area.x, closeTo(357.1656, 1e-6));
    expect(area.y, closeTo(101.0268, 1e-6));
    expect(area.width, closeTo(190.48832, 1e-6));
    expect(area.height, closeTo(84.189, 1e-6));
  });

  test('sign uses the effective box, so a 90° page swaps width and height', () async {
    _FakeEngine.documentInfo = _infoWithPages(const [
      PdfPageDimensions(width: _a4Width, height: _a4Height, rotation: 90),
    ]);
    const repository = PdfEngineSignRepository(_FakeEngine());

    await repository.sign(
      bytes: bytes,
      signatureImageBytes: imageBytes,
      pageIndex: 0,
      placement: SignaturePlacement.bottomRight,
    );

    // Displayed sideways: effectiveWidth == media height, and vice versa.
    final area = _FakeEngine.lastArea!;
    expect(area.width, closeTo(_a4Height * 0.32, 1e-6));
    expect(area.height, closeTo(_a4Width * 0.1, 1e-6));
    expect(area.x, closeTo(_a4Height * 0.6, 1e-6));
    expect(
      area.y,
      closeTo(_a4Width - _a4Width * 0.78 - _a4Width * 0.1, 1e-6),
    );
  });

  test('a 270° rotation swaps the box the same way as 90°', () async {
    _FakeEngine.documentInfo = _infoWithPages(const [
      PdfPageDimensions(width: _a4Width, height: _a4Height, rotation: 270),
    ]);
    const repository = PdfEngineSignRepository(_FakeEngine());

    await repository.sign(
      bytes: bytes,
      signatureImageBytes: imageBytes,
      pageIndex: 0,
      placement: SignaturePlacement.bottomRight,
    );

    expect(_FakeEngine.lastArea!.width, closeTo(_a4Height * 0.32, 1e-6));
  });

  test('a 180° rotation leaves the box unrotated', () async {
    _FakeEngine.documentInfo = _infoWithPages(const [
      PdfPageDimensions(width: _a4Width, height: _a4Height, rotation: 180),
    ]);
    const repository = PdfEngineSignRepository(_FakeEngine());

    await repository.sign(
      bytes: bytes,
      signatureImageBytes: imageBytes,
      pageIndex: 0,
      placement: SignaturePlacement.bottomRight,
    );

    expect(_FakeEngine.lastArea!.width, closeTo(_a4Width * 0.32, 1e-6));
  });

  test('sign throws pageOutOfRange for a negative page index', () async {
    const repository = PdfEngineSignRepository(_FakeEngine());

    await expectLater(
      () => repository.sign(
        bytes: bytes,
        signatureImageBytes: imageBytes,
        pageIndex: -1,
        placement: SignaturePlacement.bottomRight,
      ),
      throwsA(
        isA<PdfEngineException>().having(
          (error) => error.kind,
          'kind',
          PdfEngineErrorKind.pageOutOfRange,
        ),
      ),
    );
  });

  test('sign throws pageOutOfRange past the last page', () async {
    const repository = PdfEngineSignRepository(_FakeEngine());

    await expectLater(
      () => repository.sign(
        bytes: bytes,
        signatureImageBytes: imageBytes,
        pageIndex: 3,
        placement: SignaturePlacement.bottomRight,
      ),
      throwsA(
        isA<PdfEngineException>().having(
          (error) => error.kind,
          'kind',
          PdfEngineErrorKind.pageOutOfRange,
        ),
      ),
    );
  });

  test('an out-of-range page never reaches the engine', () async {
    _FakeEngine.lastPageIndex = null;
    const repository = PdfEngineSignRepository(_FakeEngine());

    await expectLater(
      () => repository.sign(
        bytes: bytes,
        signatureImageBytes: imageBytes,
        pageIndex: 9,
        placement: SignaturePlacement.bottomRight,
      ),
      throwsA(isA<PdfEngineException>()),
    );
    expect(_FakeEngine.lastPageIndex, isNull);
  });

  test('a document reporting no pages rejects page 0', () async {
    _FakeEngine.documentInfo = const PdfDocumentInfo(pageCount: 1);
    const repository = PdfEngineSignRepository(_FakeEngine());

    await expectLater(
      () => repository.sign(
        bytes: bytes,
        signatureImageBytes: imageBytes,
        pageIndex: 0,
        placement: SignaturePlacement.bottomRight,
      ),
      throwsA(
        isA<PdfEngineException>().having(
          (error) => error.kind,
          'kind',
          PdfEngineErrorKind.pageOutOfRange,
        ),
      ),
    );
  });

  test('sign leaves the stamp opacity at the engine default', () async {
    const repository = PdfEngineSignRepository(_FakeEngine());

    await repository.sign(
      bytes: bytes,
      signatureImageBytes: imageBytes,
      pageIndex: 0,
      placement: SignaturePlacement.bottomRight,
    );

    expect(_FakeEngine.lastOpacity, 1);
  });

  test('sign propagates the engine exception unchanged', () async {
    final error = Exception('stamp failed');
    _FakeEngine.stampError = error;
    const repository = PdfEngineSignRepository(_FakeEngine());

    await expectLater(
      () => repository.sign(
        bytes: bytes,
        signatureImageBytes: imageBytes,
        pageIndex: 0,
        placement: SignaturePlacement.bottomRight,
      ),
      throwsA(same(error)),
    );
  });
}
