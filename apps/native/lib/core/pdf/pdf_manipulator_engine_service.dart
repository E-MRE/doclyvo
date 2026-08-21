import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';

/// [PdfEngineService] backed by the `pdf_manipulator` package.
///
/// **This is the only file in the app allowed to import
/// `package:pdf_manipulator`.** The engine is young (see the Decisions log in
/// `NATIVE-TASKS.md`), so every one of its types — sources, sinks, params,
/// errors — is translated here into the app's own vocabulary. A future swap or
/// bug workaround touches this file and nothing else.
///
/// One [Pdf] instance is reused for every operation, as the package intends:
/// it owns the worker that keeps the work off the main thread.
final class PdfManipulatorEngineService extends PdfEngineService {
  PdfManipulatorEngineService([Pdf? pdf]) : _pdf = pdf ?? Pdf();

  final Pdf _pdf;

  @override
  Future<void> initialize() => _guard(_pdf.ensureInitialized);

  @override
  Future<PdfDocumentInfo> readDocumentInfo({
    required Uint8List bytes,
    String? password,
  }) {
    return _guard(() async {
      final doc = await _pdf.open(MemorySource(bytes), password: password);
      try {
        return PdfDocumentInfo(
          pageCount: doc.pageCount,
          version: doc.version,
          pages: doc.pages.map(_toPageDimensions).toList(),
          isEncrypted: doc.isEncrypted,
          requiresPassword: doc.requiresPassword,
        );
      } finally {
        await doc.dispose();
      }
    });
  }

  @override
  Future<Uint8List> merge({required List<Uint8List> documents}) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.merge(documents.map(MemorySource.new).toList(), output);
      return output.takeBytes();
    });
  }

  @override
  Future<List<Uint8List>> split({
    required Uint8List bytes,
    int pagesPerFile = 1,
  }) {
    return _guard(() async {
      // The engine asks for a sink per chunk and does not tell us up front how
      // many there will be, so collect them as it goes — the factory is called
      // with a monotonically increasing index.
      final chunks = <MemorySink>[];
      await _pdf.split(
        MemorySource(bytes),
        (_) {
          final sink = MemorySink();
          chunks.add(sink);
          return sink;
        },
        every: pagesPerFile,
      );
      return chunks.map((chunk) => chunk.takeBytes()).toList();
    });
  }

  @override
  Future<Uint8List> extractPages({
    required Uint8List bytes,
    required List<int> pageIndexes,
    String? password,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.extractPages(
        MemorySource(bytes),
        output,
        pages: pageIndexes,
        password: password,
      );
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> rotatePages({
    required Uint8List bytes,
    required Map<int, int> pageRotations,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.rotatePages(
        MemorySource(bytes),
        output,
        pages: pageRotations,
      );
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> rotateAllPages({
    required Uint8List bytes,
    required int degrees,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.rotateAllPages(
        MemorySource(bytes),
        output,
        degrees: degrees,
      );
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> reorderPages({
    required Uint8List bytes,
    required List<int> pageOrder,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.reorderPages(MemorySource(bytes), output, order: pageOrder);
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.watermark(
        MemorySource(bytes),
        output,
        text: options.text,
        pages: _toPdfPages(options.pageIndexes),
        style: PdfWatermarkStyle(
          fontSize: options.fontSize,
          opacity: options.opacity,
          rotation: options.rotation,
        ),
        position: _toWatermarkPosition(options.placement),
        layer: options.behindContent
            ? PdfWatermarkLayer.background
            : PdfWatermarkLayer.foreground,
      );
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    int imageQuality = 75,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.compress(
        MemorySource(bytes),
        output,
        imageQuality: imageQuality,
      );
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.encrypt(
        MemorySource(bytes),
        output,
        encryption: PdfEncryptionConfig(
          ownerPassword: options.ownerPassword ?? options.password,
          userPassword: options.password,
          permissions: PdfPermissions(
            print: options.allowPrinting,
            printHq: options.allowPrinting,
            modify: options.allowEditing,
            copy: options.allowCopying,
            annotate: options.allowEditing,
            fillForms: options.allowEditing,
            assemble: options.allowEditing,
          ),
        ),
      );
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> removeProtection({
    required Uint8List bytes,
    required String password,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.decrypt(MemorySource(bytes), output, password: password);
      return output.takeBytes();
    });
  }

  @override
  Future<Uint8List> addImageStamp({
    required Uint8List bytes,
    required Uint8List imageBytes,
    required int pageIndex,
    required PdfStampArea area,
    double opacity = 1,
  }) {
    return _guard(() async {
      final output = MemorySink();
      await _pdf.addImageStamp(
        MemorySource(bytes),
        output,
        page: pageIndex,
        imageData: MemorySource(imageBytes),
        rect: PdfRect(
          x: area.x,
          y: area.y,
          width: area.width,
          height: area.height,
        ),
        opacity: opacity,
      );
      return output.takeBytes();
    });
  }

  @override
  Stream<PdfPageThumbnail> renderThumbnails({
    required Uint8List bytes,
    List<int>? pageIndexes,
    int maxSize = 200,
    String? password,
  }) async* {
    final doc = await _guard(
      () => _pdf.open(MemorySource(bytes), password: password),
    );
    try {
      // The render stream yields images in the order the pages were requested
      // but carries no page index of its own, so pair each event with the
      // index it was asked for.
      final requested =
          pageIndexes ?? List.generate(doc.pageCount, (index) => index);
      var position = 0;

      final pages = doc.render(
        pages: _toPdfPages(pageIndexes),
        size: PdfRenderSize.thumbnail(maxSize),
      );

      await for (final page in pages.handleError(_rethrowMapped)) {
        yield PdfPageThumbnail(
          pageIndex: position < requested.length
              ? requested[position]
              : position,
          width: page.width,
          height: page.height,
          pngBytes: page.data,
        );
        position++;
      }
    } finally {
      await doc.dispose();
    }
  }

  @override
  Future<void> dispose() => _pdf.dispose();

  PdfPageDimensions _toPageDimensions(PdfPageInfo page) => PdfPageDimensions(
        index: page.index,
        width: page.width,
        height: page.height,
        rotation: page.rotation,
      );

  PdfPages _toPdfPages(List<int>? pageIndexes) =>
      pageIndexes == null ? const PdfPages.all() : PdfPages.list(pageIndexes);

  PdfWatermarkPosition _toWatermarkPosition(PdfWatermarkPlacement placement) {
    return switch (placement) {
      PdfWatermarkPlacement.center => const PdfWatermarkPosition.center(),
      PdfWatermarkPlacement.tiled => const PdfWatermarkPosition.tiled(),
      PdfWatermarkPlacement.topLeft =>
        const PdfWatermarkPosition.corner(PdfCorner.topLeft),
      PdfWatermarkPlacement.topRight =>
        const PdfWatermarkPosition.corner(PdfCorner.topRight),
      PdfWatermarkPlacement.bottomLeft =>
        const PdfWatermarkPosition.corner(PdfCorner.bottomLeft),
      PdfWatermarkPlacement.bottomRight =>
        const PdfWatermarkPosition.corner(PdfCorner.bottomRight),
    };
  }

  /// Runs [action], translating the engine's sealed `PdfError` hierarchy into
  /// the app's own [PdfEngineException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PdfError catch (error) {
      throw _toEngineException(error);
    }
  }

  Never _rethrowMapped(Object error, StackTrace stackTrace) {
    Error.throwWithStackTrace(
      error is PdfError ? _toEngineException(error) : error,
      stackTrace,
    );
  }

  PdfEngineException _toEngineException(PdfError error) {
    final kind = switch (error) {
      PdfPasswordRequired() => PdfEngineErrorKind.passwordRequired,
      PdfWrongPassword() => PdfEngineErrorKind.wrongPassword,
      PdfCorrupted() => PdfEngineErrorKind.corrupted,
      PdfPageRangeError() => PdfEngineErrorKind.pageOutOfRange,
      PdfUnsupported() => PdfEngineErrorKind.unsupported,
      PdfCancelled() => PdfEngineErrorKind.cancelled,
      PdfInvalidArgument() ||
      PdfIoError() ||
      PdfExtractionFailed() ||
      PdfEngineError() ||
      PdfSearchError() ||
      PdfCryptoError() =>
        PdfEngineErrorKind.engineFailure,
    };
    return PdfEngineException(error.message, kind: kind);
  }
}
