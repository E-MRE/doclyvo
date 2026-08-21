import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';

/// One page in the Rotate tool's grid: its zero-based index, its rendered
/// preview once it has streamed in, and whether the user has selected it for
/// the next rotate action.
///
/// [thumbnail] starts `null` — `renderThumbnails` streams previews in one at
/// a time, so the grid shows a placeholder tile until its entry's preview
/// arrives, same pattern as `MergeFileEntry.pageCount`.
final class RotatePageEntry {
  const RotatePageEntry({
    required this.pageIndex,
    this.thumbnail,
    this.selected = false,
  });

  final int pageIndex;
  final PdfPageThumbnail? thumbnail;
  final bool selected;

  RotatePageEntry copyWith({PdfPageThumbnail? thumbnail, bool? selected}) =>
      RotatePageEntry(
        pageIndex: pageIndex,
        thumbnail: thumbnail ?? this.thumbnail,
        selected: selected ?? this.selected,
      );
}
