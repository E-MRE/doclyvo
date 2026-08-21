// Covers PdfEngineCompressRepository as a thin adapter: it must forward the
// selected quality's imageQuality to PdfEngineService.compress unchanged and
// hand back exactly what the engine returns.

import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/features/compress/data/repositories/pdf_engine_compress_repository.dart';
import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeEngine extends PdfEngineService {
  const _FakeEngine();

  static Uint8List? lastBytes;
  static int? lastImageQuality;
  static Uint8List result = Uint8List.fromList([1, 2, 3]);

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    int imageQuality = 75,
  }) async {
    lastBytes = bytes;
    lastImageQuality = imageQuality;
    return result;
  }

  @override
  Future<PdfDocumentInfo> readDocumentInfo({
    required Uint8List bytes,
    String? password,
  }) => throw UnimplementedError();

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
  test("forwards the quality preset's imageQuality to the engine", () async {
    const repository = PdfEngineCompressRepository(_FakeEngine());
    final bytes = Uint8List.fromList([9, 8, 7]);

    final result = await repository.compress(
      bytes: bytes,
      quality: CompressQuality.high,
    );

    expect(_FakeEngine.lastBytes, same(bytes));
    expect(_FakeEngine.lastImageQuality, CompressQuality.high.imageQuality);
    expect(result, same(_FakeEngine.result));
  });
}
