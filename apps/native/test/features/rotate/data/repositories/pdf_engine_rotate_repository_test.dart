// Covers PdfEngineRotateRepository as a thin adapter: readPageCount,
// rotatePages and renderThumbnails must all forward to PdfEngineService
// unchanged, and forward its results back unchanged too.

import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/rotate/data/repositories/pdf_engine_rotate_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static Uint8List? lastBytes;
  static Map<int, int>? lastPageRotations;
  static Uint8List rotateResult = Uint8List(0);
  static int pageCountResult = 0;
  static Stream<PdfPageThumbnail> thumbnailsResult = const Stream.empty();

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
  }) async {
    lastBytes = bytes;
    lastPageRotations = pageRotations;
    return rotateResult;
  }

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
  }) => throw UnimplementedError();

  @override
  Stream<PdfPageThumbnail> renderThumbnails({
    required Uint8List bytes,
    List<int>? pageIndexes,
    int maxSize = 200,
    String? password,
  }) {
    lastBytes = bytes;
    return thumbnailsResult;
  }
}

void main() {
  test('readPageCount forwards the engine document info page count', () async {
    _FakeEngine.pageCountResult = 7;
    const repository = PdfEngineRotateRepository(_FakeEngine());

    final count = await repository.readPageCount(
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(count, 7);
  });

  test(
    'rotatePages forwards bytes and pageRotations unchanged and returns the result',
    () async {
      final bytes = Uint8List.fromList([9, 8, 7]);
      final pageRotations = {0: 90, 2: 180};
      _FakeEngine.rotateResult = Uint8List.fromList([1, 1, 1]);
      const repository = PdfEngineRotateRepository(_FakeEngine());

      final result = await repository.rotatePages(
        bytes: bytes,
        pageRotations: pageRotations,
      );

      expect(_FakeEngine.lastBytes, same(bytes));
      expect(_FakeEngine.lastPageRotations, same(pageRotations));
      expect(result, same(_FakeEngine.rotateResult));
    },
  );

  test(
    'renderThumbnails forwards bytes unchanged and yields the engine stream unchanged',
    () async {
      final bytes = Uint8List.fromList([4, 5, 6]);
      final first = PdfPageThumbnail(
        pageIndex: 0,
        width: 10,
        height: 20,
        pngBytes: Uint8List.fromList([1]),
      );
      final second = PdfPageThumbnail(
        pageIndex: 1,
        width: 10,
        height: 20,
        pngBytes: Uint8List.fromList([2]),
      );
      _FakeEngine.thumbnailsResult = Stream.fromIterable([first, second]);
      const repository = PdfEngineRotateRepository(_FakeEngine());

      final events = await repository
          .renderThumbnails(bytes: bytes)
          .toList();

      expect(_FakeEngine.lastBytes, same(bytes));
      expect(events, [same(first), same(second)]);
    },
  );
}
