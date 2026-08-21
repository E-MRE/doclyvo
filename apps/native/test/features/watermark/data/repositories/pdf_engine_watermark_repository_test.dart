// Covers PdfEngineWatermarkRepository as a thin adapter: readPageCount must
// forward to PdfEngineService.readDocumentInfo's page count, addWatermark
// must forward bytes and options unchanged, and renderFirstPageThumbnail
// must request just page 0 and unwrap the single-element stream (or null
// when the engine returns nothing).

import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/watermark/data/repositories/pdf_engine_watermark_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static Uint8List? lastBytes;
  static PdfWatermarkOptions? lastOptions;
  static Uint8List watermarkResult = Uint8List(0);
  static int pageCountResult = 0;
  static List<int>? lastPageIndexes;
  static List<PdfPageThumbnail> thumbnails = [];

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
  }) async {
    lastBytes = bytes;
    lastOptions = options;
    return watermarkResult;
  }

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
  }) => throw UnimplementedError();

  @override
  Stream<PdfPageThumbnail> renderThumbnails({
    required Uint8List bytes,
    List<int>? pageIndexes,
    int maxSize = 200,
    String? password,
  }) {
    lastPageIndexes = pageIndexes;
    return Stream.fromIterable(thumbnails);
  }
}

void main() {
  test('readPageCount forwards the engine document info page count', () async {
    _FakeEngine.pageCountResult = 7;
    const repository = PdfEngineWatermarkRepository(_FakeEngine());

    final count = await repository.readPageCount(
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(count, 7);
  });

  test('addWatermark forwards bytes and options unchanged', () async {
    final bytes = Uint8List.fromList([9, 8, 7]);
    const options = PdfWatermarkOptions(text: 'Doclyvo', opacity: 0.5);
    _FakeEngine.watermarkResult = Uint8List.fromList([1, 1, 1]);
    const repository = PdfEngineWatermarkRepository(_FakeEngine());

    final result = await repository.addWatermark(bytes: bytes, options: options);

    expect(_FakeEngine.lastBytes, same(bytes));
    expect(_FakeEngine.lastOptions, same(options));
    expect(result, same(_FakeEngine.watermarkResult));
  });

  test('renderFirstPageThumbnail requests page 0 and returns the single thumbnail', () async {
    final thumbnail = PdfPageThumbnail(
      pageIndex: 0,
      width: 100,
      height: 200,
      pngBytes: Uint8List.fromList([1, 2, 3]),
    );
    _FakeEngine.thumbnails = [thumbnail];
    const repository = PdfEngineWatermarkRepository(_FakeEngine());

    final result = await repository.renderFirstPageThumbnail(
      bytes: Uint8List.fromList([0]),
    );

    expect(_FakeEngine.lastPageIndexes, const [0]);
    expect(result, same(thumbnail));
  });

  test('renderFirstPageThumbnail returns null when the engine stream is empty', () async {
    _FakeEngine.thumbnails = [];
    const repository = PdfEngineWatermarkRepository(_FakeEngine());

    final result = await repository.renderFirstPageThumbnail(
      bytes: Uint8List.fromList([0]),
    );

    expect(result, isNull);
  });
}
