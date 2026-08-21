import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/reorder/data/repositories/reorder_repository.dart';
import 'package:doclyvo/features/reorder/presentation/cubit/reorder_state.dart';

/// Drives the Reorder tool's async operations only.
///
/// The selected file and its page order both live in the screen's local
/// state, not here — same reasoning as `RotateCubit`/`MergeCubit`.
final class ReorderCubit extends BaseCubit<ReorderState> {
  ReorderCubit(this._repository) : super(const ReorderInitial());

  final ReorderRepository _repository;

  /// Reads the page count of a freshly-picked file, for the grid's initial
  /// placeholder-tile count — deliberately does not touch [ReorderState],
  /// same reasoning as `RotateCubit.readPageCount`.
  Future<int?> readPageCount({required Uint8List bytes}) async {
    try {
      return await _repository.readPageCount(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  /// Streams a preview per page for the reorder grid. Forwarded as-is.
  Stream<PdfPageThumbnail> renderThumbnails({required Uint8List bytes}) {
    return _repository.renderThumbnails(bytes: bytes);
  }

  /// Rewrites the document with its pages in [pageOrder].
  ///
  /// [pageCount] is display metadata derived from the same list [pageOrder]
  /// was built from, not re-derived here.
  Future<void> reorder({
    required Uint8List bytes,
    required List<int> pageOrder,
    required int pageCount,
  }) async {
    return safeCall<Uint8List>(
      action: () => _repository.reorderPages(bytes: bytes, pageOrder: pageOrder),
      loadingState: const ReorderLoading(),
      successState: (data) =>
          ReorderSuccess(reorderedBytes: data, pageCount: pageCount),
      errorState: (message) => ReorderError(message: message),
    );
  }

  /// Back to the idle step, discarding the previous result/error.
  void reset() => safeEmit(const ReorderInitial());
}
