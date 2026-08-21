import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';

/// One file in the Merge tool's reorderable list — a picked PDF plus its
/// page count once it has been read.
///
/// [pageCount] starts `null` and is filled in asynchronously (same pattern
/// as Split's page-count lookup): a failure to read it (encrypted/corrupted
/// file) does not block the entry from sitting in the list, it just leaves
/// the count blank, matching `design/Merge.dc.html`'s per-row "{pages}
/// sayfa" text having no error branch of its own.
final class MergeFileEntry {
  const MergeFileEntry({required this.file, this.pageCount});

  final PickedPdfFile file;
  final int? pageCount;

  MergeFileEntry copyWithPageCount(int? pageCount) =>
      MergeFileEntry(file: file, pageCount: pageCount);
}
