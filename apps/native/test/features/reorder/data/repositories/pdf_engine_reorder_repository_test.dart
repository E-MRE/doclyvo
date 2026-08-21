// Covers PdfEngineReorderRepository as a thin adapter: it must forward bytes
// to PdfEngineService.readDocumentInfo/reorderPages/renderThumbnails
// unchanged and hand back whatever the engine produces.

import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/reorder/data/repositories/pdf_engine_reorder_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static Uint8List? lastReadBytes;
  static int pageCountResult = 0;

  static Uint8List? lastReorderBytes;
  static List<int>? lastPageOrder;
  static Uint8List reorderResult = Uint8List(0);

  static Uint8List? lastThumbnailBytes;
  static Stream<PdfPageThumbnail> thumbnailsResult = const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<PdfDocumentInfo> readDocumentInfo({
    required Uint8List bytes,
    String? password,
  }) async {
    lastReadBytes = bytes;
    return PdfDocumentInfo(pageCount: pageCountResult);
  }

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
  }) async {
    lastReorderBytes = bytes;
    lastPageOrder = pageOrder;
    return reorderResult;
  }

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
    lastThumbnailBytes = bytes;
    return thumbnailsResult;
  }
}

void main() {
  test('readPageCount forwards the engine document info page count', () async {
    _FakeEngine.pageCountResult = 7;
    const repository = PdfEngineReorderRepository(_FakeEngine());
    final bytes = Uint8List.fromList([1, 2, 3]);

    final count = await repository.readPageCount(bytes: bytes);

    expect(count, 7);
    expect(_FakeEngine.lastReadBytes, same(bytes));
  });

  test('reorderPages forwards bytes and pageOrder unchanged to the engine', () async {
    final bytes = Uint8List.fromList([9, 8, 7]);
    final pageOrder = [2, 0, 1];
    _FakeEngine.reorderResult = Uint8List.fromList([5, 5, 5]);
    const repository = PdfEngineReorderRepository(_FakeEngine());

    final result = await repository.reorderPages(
      bytes: bytes,
      pageOrder: pageOrder,
    );

    expect(_FakeEngine.lastReorderBytes, same(bytes));
    expect(_FakeEngine.lastPageOrder, same(pageOrder));
    expect(result, same(_FakeEngine.reorderResult));
  });

  test('renderThumbnails forwards bytes and yields the engine stream unchanged', () async {
    final bytes = Uint8List.fromList([4, 4, 4]);
    final thumbnails = [
      PdfPageThumbnail(
        pageIndex: 0,
        width: 10,
        height: 20,
        pngBytes: Uint8List.fromList([1]),
      ),
      PdfPageThumbnail(
        pageIndex: 1,
        width: 10,
        height: 20,
        pngBytes: Uint8List.fromList([2]),
      ),
    ];
    _FakeEngine.thumbnailsResult = Stream.fromIterable(thumbnails);
    const repository = PdfEngineReorderRepository(_FakeEngine());

    final result = await repository.renderThumbnails(bytes: bytes).toList();

    expect(_FakeEngine.lastThumbnailBytes, same(bytes));
    expect(result, thumbnails);
  });
}
