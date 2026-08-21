import 'dart:typed_data';

import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/merge/data/repositories/merge_repository.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_state.dart';

/// Drives the Merge tool's async operation only.
///
/// The selected files, their order, and their individual page counts all
/// live in the screen's local state, not here — `ResultPanel` is a
/// controlled widget driven by its caller (see the P2-1/P2-3 Decisions log
/// entries), and `BaseCubit`'s 4-state pattern keeps `Initial`/`Loading`
/// free of fields. There are no tool settings either (`design/Merge.dc.html`
/// has none), so this cubit only tracks whether a merge call is running
/// and, once done, its result.
final class MergeCubit extends BaseCubit<MergeState> {
  MergeCubit(this._repository) : super(const MergeInitial());

  final MergeRepository _repository;

  /// Reads the page count of a freshly-picked file, for its list-row summary
  /// and the "Toplam sayfa" total — deliberately does not touch [MergeState]:
  /// this is metadata for display, not the tool's actual action, so a
  /// failure here (e.g. an encrypted or corrupted file) shouldn't surface as
  /// a `MergeError` before the user has even pressed the start button.
  /// `null` means "unknown"; the screen falls back to hiding the count for
  /// that row rather than showing a wrong one.
  Future<int?> readPageCount({required Uint8List bytes}) async {
    try {
      return await _repository.readPageCount(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  /// Merges [documents] (already in the user's chosen order) into one PDF.
  ///
  /// [fileCount]/[totalPages] are display metadata computed by the caller
  /// from the same list [documents] was built from, not re-derived here.
  Future<void> merge({
    required List<Uint8List> documents,
    required int fileCount,
    required int totalPages,
  }) async {
    return safeCall<Uint8List>(
      action: () => _repository.merge(documents: documents),
      loadingState: const MergeLoading(),
      successState: (data) => MergeSuccess(
        mergedBytes: data,
        fileCount: fileCount,
        totalPages: totalPages,
      ),
      errorState: (message) => MergeError(message: message),
    );
  }

  /// Back to the idle step, discarding the previous result/error.
  void reset() => safeEmit(const MergeInitial());
}
