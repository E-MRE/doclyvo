import 'dart:typed_data';

abstract class MergeState {
  const MergeState();
}

/// Before a merge action has run, or after a reset.
///
/// The selected files (and their order) are owned by the screen, not this
/// state — see `MergeCubit` for why (same reasoning as `CompressCubit`/
/// `SplitCubit`).
final class MergeInitial implements MergeState {
  const MergeInitial();
}

final class MergeLoading implements MergeState {
  const MergeLoading();
}

final class MergeSuccess implements MergeState {
  const MergeSuccess({
    required this.mergedBytes,
    required this.fileCount,
    required this.totalPages,
  });

  final Uint8List mergedBytes;
  final int fileCount;
  final int totalPages;
}

final class MergeError implements MergeState {
  const MergeError({this.message = ''});
  final String message;
}
