import 'dart:typed_data';

abstract class SplitState {
  const SplitState();
}

/// Before a split action has run, or after a reset.
///
/// The selected file is owned by the screen, not this state — see
/// `SplitCubit` for why (same reasoning as `CompressCubit`).
final class SplitInitial implements SplitState {
  const SplitInitial();
}

final class SplitLoading implements SplitState {
  const SplitLoading();
}

final class SplitSuccess implements SplitState {
  const SplitSuccess({required this.zipBytes, required this.pageCount});

  final Uint8List zipBytes;
  final int pageCount;
}

final class SplitError implements SplitState {
  const SplitError({this.message = ''});
  final String message;
}
