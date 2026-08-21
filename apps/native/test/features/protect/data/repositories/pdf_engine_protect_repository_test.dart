// Covers PdfEngineProtectRepository as a thin adapter: readPageCount must
// forward to PdfEngineService.readDocumentInfo's page count, protect must
// forward bytes and options unchanged, and an exception raised by the engine
// must propagate to the caller unchanged.

import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/protect/data/repositories/pdf_engine_protect_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static Uint8List? lastBytes;
  static PdfProtectionOptions? lastOptions;
  static Uint8List protectResult = Uint8List(0);
  static int pageCountResult = 0;
  static Exception? protectError;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<PdfDocumentInfo> readDocumentInfo({
    required Uint8List bytes,
    String? password,
  }) async => PdfDocumentInfo(pageCount: pageCountResult);

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
  }) async {
    lastBytes = bytes;
    lastOptions = options;
    final error = protectError;
    if (error != null) throw error;
    return protectResult;
  }

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
  }) => throw UnimplementedError();

  @override
  Stream<PdfPageThumbnail> renderThumbnails({
    required Uint8List bytes,
    List<int>? pageIndexes,
    int maxSize = 200,
    String? password,
  }) => throw UnimplementedError();
}

void main() {
  setUp(() {
    _FakeEngine.protectError = null;
  });

  test('readPageCount forwards the engine document info page count', () async {
    _FakeEngine.pageCountResult = 7;
    const repository = PdfEngineProtectRepository(_FakeEngine());

    final count = await repository.readPageCount(
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(count, 7);
  });

  test('protect forwards bytes and options unchanged', () async {
    final bytes = Uint8List.fromList([9, 8, 7]);
    const options = PdfProtectionOptions(password: 'Doclyvo1!', allowPrinting: false);
    _FakeEngine.protectResult = Uint8List.fromList([1, 1, 1]);
    const repository = PdfEngineProtectRepository(_FakeEngine());

    final result = await repository.protect(bytes: bytes, options: options);

    expect(_FakeEngine.lastBytes, same(bytes));
    expect(_FakeEngine.lastOptions, same(options));
    expect(result, same(_FakeEngine.protectResult));
  });

  test('protect propagates the engine exception unchanged', () async {
    final error = Exception('encryption failed');
    _FakeEngine.protectError = error;
    const repository = PdfEngineProtectRepository(_FakeEngine());

    await expectLater(
      () => repository.protect(
        bytes: Uint8List.fromList([1]),
        options: const PdfProtectionOptions(password: 'Doclyvo1!'),
      ),
      throwsA(same(error)),
    );
  });
}
