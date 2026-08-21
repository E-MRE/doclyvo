// Covers PdfEngineMergeRepository as a thin adapter: it must forward the
// document list to PdfEngineService.merge unchanged, in order, and forward
// readDocumentInfo's page count unchanged.

import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/merge/data/repositories/pdf_engine_merge_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static List<Uint8List>? lastDocuments;
  static Uint8List mergedResult = Uint8List(0);
  static int pageCountResult = 0;

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
  Future<Uint8List> merge({required List<Uint8List> documents}) async {
    lastDocuments = documents;
    return mergedResult;
  }

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
  test('readPageCount forwards the engine document info page count', () async {
    _FakeEngine.pageCountResult = 12;
    const repository = PdfEngineMergeRepository(_FakeEngine());

    final count = await repository.readPageCount(
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(count, 12);
  });

  test('merge forwards the document list unchanged, in order', () async {
    final documents = [
      Uint8List.fromList([1, 1, 1]),
      Uint8List.fromList([2, 2, 2]),
      Uint8List.fromList([3, 3, 3]),
    ];
    final expected = Uint8List.fromList([9, 9, 9]);
    _FakeEngine.mergedResult = expected;
    const repository = PdfEngineMergeRepository(_FakeEngine());

    final result = await repository.merge(documents: documents);

    expect(result, same(expected));
    expect(_FakeEngine.lastDocuments, same(documents));
  });
}
