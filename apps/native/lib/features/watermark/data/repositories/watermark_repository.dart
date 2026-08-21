import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';

/// Stamps text across a PDF's pages, and renders a first-page preview to
/// show the settings against before committing.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as `CompressRepository`) — this is
/// Phase 3A, so the concrete implementation calls `PdfEngineService`, never
/// `NetworkService`.
abstract class WatermarkRepository {
  /// Page count of the document at [bytes], read without modifying it —
  /// drives the "{count} sayfaya uygulandı" result copy.
  Future<int> readPageCount({required Uint8List bytes});

  /// Renders just the first page, for the live settings preview —
  /// `null` when the document has no pages or rendering fails.
  Future<PdfPageThumbnail?> renderFirstPageThumbnail({
    required Uint8List bytes,
  });

  /// Stamps every page of [bytes] per [options].
  Future<Uint8List> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
  });
}
