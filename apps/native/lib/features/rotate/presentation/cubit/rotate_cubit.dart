import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/rotate/data/repositories/rotate_repository.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_state.dart';

/// Drives the Rotate tool's async operations only.
///
/// The selected file, its page previews and which pages are selected all live
/// in the screen's local state, not here — `ResultPanel` is a controlled
/// widget driven by its caller (see the P2-1/P2-3 Decisions log entries), and
/// `BaseCubit`'s 4-state pattern keeps `Initial`/`Loading` free of fields.
final class RotateCubit extends BaseCubit<RotateState> {
  RotateCubit(this._repository) : super(const RotateInitial());

  final RotateRepository _repository;

  /// Reads the page count of a freshly-picked file, for the grid's initial
  /// placeholder-tile count — deliberately does not touch [RotateState]: this
  /// is metadata for display, not the tool's actual action, so a failure
  /// here (e.g. an encrypted or corrupted file) shouldn't surface as a
  /// `RotateError` before the user has even pressed the start button. `null`
  /// means "unknown"; the screen falls back to hiding the grid for that file.
  Future<int?> readPageCount({required Uint8List bytes}) async {
    try {
      return await _repository.readPageCount(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  /// Streams a preview per page for the selection grid. Forwarded as-is —
  /// the screen owns matching each event to its `RotatePageEntry` and
  /// tolerating a stream error (previews just stay blank placeholders).
  Stream<PdfPageThumbnail> renderThumbnails({required Uint8List bytes}) {
    return _repository.renderThumbnails(bytes: bytes);
  }

  /// Rotates every page in [pageRotations] by its mapped clockwise degrees.
  ///
  /// [pageCount]/[rotatedPageCount] are display metadata computed by the
  /// caller from the same selection [pageRotations] was built from, not
  /// re-derived here.
  Future<void> rotate({
    required Uint8List bytes,
    required Map<int, int> pageRotations,
    required int pageCount,
    required int rotatedPageCount,
  }) async {
    return safeCall<Uint8List>(
      action: () =>
          _repository.rotatePages(bytes: bytes, pageRotations: pageRotations),
      loadingState: const RotateLoading(),
      successState: (data) => RotateSuccess(
        rotatedBytes: data,
        pageCount: pageCount,
        rotatedPageCount: rotatedPageCount,
      ),
      errorState: (message) => RotateError(message: message),
    );
  }

  /// Back to the idle step, discarding the previous result/error.
  void reset() => safeEmit(const RotateInitial());
}
