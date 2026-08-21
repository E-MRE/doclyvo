import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_document_info.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/pdf/models/pdf_stamp_area.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';

/// On-device PDF processing, for the tools that never touch the backend.
///
/// This is the only sanctioned way to manipulate a PDF client-side: no feature
/// may import the underlying engine package directly (see `CLAUDE.md`). Every
/// operation takes and returns raw bytes, so the interface stays free of
/// `dart:io` and works the same on mobile, desktop and web — reading a picked
/// file into bytes and writing the result back to disk happens at the feature
/// edge, not here.
///
/// Page indexes are always zero-based. Failures surface as
/// [PdfEngineException], which `BaseCubit.safeCall` turns into an error state.
abstract class PdfEngineService {
  const PdfEngineService();

  /// Warms up the engine — on native platforms this loads the prebuilt binary.
  ///
  /// Safe to call more than once. Calling it during app start keeps the first
  /// tool run from paying the load cost.
  Future<void> initialize();

  /// Reads page count, page sizes and encryption status without modifying the
  /// document.
  ///
  /// Pass [password] for an encrypted document, otherwise the call fails with
  /// [PdfEngineErrorKind.passwordRequired].
  Future<PdfDocumentInfo> readDocumentInfo({
    required Uint8List bytes,
    String? password,
  });

  /// Concatenates [documents] in the given order into one PDF (Merge).
  Future<Uint8List> merge({required List<Uint8List> documents});

  /// Cuts [bytes] into chunks of [pagesPerFile] pages each (Split).
  ///
  /// The default of one page per file produces one PDF per page. Returns the
  /// chunks in document order; assembling them into an archive, if the UI wants
  /// one, is the feature's job.
  Future<List<Uint8List>> split({
    required Uint8List bytes,
    int pagesPerFile = 1,
  });

  /// Builds a new PDF containing only [pageIndexes], in the order given.
  Future<Uint8List> extractPages({
    required Uint8List bytes,
    required List<int> pageIndexes,
    String? password,
  });

  /// Rotates specific pages (Rotate).
  ///
  /// [pageRotations] maps a page index to its clockwise rotation in degrees.
  Future<Uint8List> rotatePages({
    required Uint8List bytes,
    required Map<int, int> pageRotations,
  });

  /// Rotates every page by [degrees] clockwise.
  Future<Uint8List> rotateAllPages({
    required Uint8List bytes,
    required int degrees,
  });

  /// Rewrites the document with its pages in [pageOrder] (Reorder).
  ///
  /// [pageOrder] holds the source page index for each output position.
  Future<Uint8List> reorderPages({
    required Uint8List bytes,
    required List<int> pageOrder,
  });

  /// Stamps text across the document (Watermark).
  Future<Uint8List> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
  });

  /// Re-encodes images and rewrites the file to shrink it (Compress).
  ///
  /// [imageQuality] runs from `1` (smallest) to `100` (best quality).
  Future<Uint8List> compress({
    required Uint8List bytes,
    int imageQuality = 75,
  });

  /// Encrypts the document with a password and permission flags (Protect).
  Future<Uint8List> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
  });

  /// Strips encryption from a document, given its current [password].
  Future<Uint8List> removeProtection({
    required Uint8List bytes,
    required String password,
  });

  /// Places [imageBytes] on [pageIndex] inside [area] (Sign).
  Future<Uint8List> addImageStamp({
    required Uint8List bytes,
    required Uint8List imageBytes,
    required int pageIndex,
    required PdfStampArea area,
    double opacity = 1,
  });

  /// Renders page previews as PNG images, one event per page.
  ///
  /// [pageIndexes] selects the pages to render, or `null` for all of them.
  /// [maxSize] caps the longest edge of each preview in pixels. Streaming means
  /// a long document's first thumbnails reach the UI before the last page is
  /// rendered.
  Stream<PdfPageThumbnail> renderThumbnails({
    required Uint8List bytes,
    List<int>? pageIndexes,
    int maxSize = 200,
    String? password,
  });

  /// Releases the engine and any memory it holds.
  Future<void> dispose();
}
