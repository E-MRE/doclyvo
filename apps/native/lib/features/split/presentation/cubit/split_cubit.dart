import 'dart:typed_data';

import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/split/data/repositories/split_repository.dart';
import 'package:doclyvo/features/split/domain/models/split_result.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_state.dart';

/// Drives the Split tool's async operation only.
///
/// The selected file lives in the screen's local state, not here —
/// `UploadDropzone`/`ResultPanel` are controlled widgets driven by their
/// caller (see the P2-1/P2-3 Decisions log entries), and `BaseCubit`'s
/// 4-state pattern keeps `Initial`/`Loading` free of fields. There are no
/// tool settings to track either (`design/Split.dc.html` has none), so this
/// cubit only tracks whether a split call is running and, once done, its
/// result.
final class SplitCubit extends BaseCubit<SplitState> {
  SplitCubit(this._repository) : super(const SplitInitial());

  final SplitRepository _repository;

  /// Reads the page count of a freshly-picked file, for the idle-state
  /// summary — deliberately does not touch [SplitState]: this is metadata for
  /// display, not the tool's actual action, so a failure here (e.g. an
  /// encrypted or corrupted file) shouldn't surface as a `SplitError` before
  /// the user has even pressed the start button. `null` means "unknown";
  /// the screen falls back to hiding the count rather than showing it.
  Future<int?> readPageCount({required Uint8List bytes}) async {
    try {
      return await _repository.readPageCount(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  Future<void> split({required Uint8List bytes}) async {
    return safeCall<SplitResult>(
      action: () => _repository.split(bytes: bytes),
      loadingState: const SplitLoading(),
      successState: (data) => SplitSuccess(
        zipBytes: data.zipBytes,
        pageCount: data.pageCount,
      ),
      errorState: (message) => SplitError(message: message),
    );
  }

  /// Back to the idle step, discarding the previous result/error.
  void reset() => safeEmit(const SplitInitial());
}
