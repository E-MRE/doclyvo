// Covers PdfEngineSplitRepository as a thin adapter plus its zip assembly:
// it must forward bytes to PdfEngineService.split unchanged, and the returned
// SplitResult must be a valid zip containing one entry per page.

import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/split/data/repositories/pdf_engine_split_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static Uint8List? lastBytes;
  static List<Uint8List> pages = [];
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
  Future<Uint8List> merge({required List<Uint8List> documents}) =>
      throw UnimplementedError();

  @override
  Future<List<Uint8List>> split({
    required Uint8List bytes,
    int pagesPerFile = 1,
  }) async {
    lastBytes = bytes;
    return pages;
  }

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
    _FakeEngine.pageCountResult = 7;
    const repository = PdfEngineSplitRepository(_FakeEngine());

    final count = await repository.readPageCount(
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(count, 7);
  });

  test('split forwards bytes and zips each returned page as one entry', () async {
    final bytes = Uint8List.fromList([9, 8, 7]);
    _FakeEngine.pages = [
      Uint8List.fromList([1, 1, 1]),
      Uint8List.fromList([2, 2, 2]),
      Uint8List.fromList([3, 3, 3]),
    ];
    const repository = PdfEngineSplitRepository(_FakeEngine());

    final result = await repository.split(bytes: bytes);

    expect(_FakeEngine.lastBytes, same(bytes));
    expect(result.pageCount, 3);

    final archive = ZipDecoder().decodeBytes(result.zipBytes);
    expect(archive.files, hasLength(3));
    expect(archive.files.map((f) => f.name), [
      'sayfa-1.pdf',
      'sayfa-2.pdf',
      'sayfa-3.pdf',
    ]);
  });

  test('zero-pads entry names when the page count needs more digits', () async {
    _FakeEngine.pages = List.generate(
      11,
      (i) => Uint8List.fromList([i]),
    );
    const repository = PdfEngineSplitRepository(_FakeEngine());

    final result = await repository.split(
      bytes: Uint8List.fromList([0]),
    );

    final archive = ZipDecoder().decodeBytes(result.zipBytes);
    expect(archive.files.first.name, 'sayfa-01.pdf');
    expect(archive.files.last.name, 'sayfa-11.pdf');
  });
}
