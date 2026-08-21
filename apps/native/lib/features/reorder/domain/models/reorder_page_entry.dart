import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';

/// One page in the Reorder tool's grid: its original zero-based index and its
/// rendered preview once it has streamed in.
///
/// The list's *position* (not [pageIndex]) is the current order — the screen
/// moves entries with up/down arrows the same way `MergeFileList` moves file
/// rows, then reads `pageIndex` off each entry in list order to build
/// `PdfEngineService.reorderPages`'s `pageOrder`.
///
/// [thumbnail] starts `null` — `renderThumbnails` streams previews in one at
/// a time, so the grid shows a placeholder tile until its entry's preview
/// arrives, same pattern as `RotatePageEntry`.
final class ReorderPageEntry {
  const ReorderPageEntry({required this.pageIndex, this.thumbnail});

  final int pageIndex;
  final PdfPageThumbnail? thumbnail;

  ReorderPageEntry copyWithThumbnail(PdfPageThumbnail thumbnail) =>
      ReorderPageEntry(pageIndex: pageIndex, thumbnail: thumbnail);
}
