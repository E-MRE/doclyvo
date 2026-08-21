import 'dart:typed_data';

abstract class RotateState {
  const RotateState();
}

/// Before a rotate action has run, or after a reset.
///
/// The selected file, its page previews and their selection all live on the
/// screen, not here — see `RotateCubit` for why (same reasoning as
/// `MergeCubit`/`SplitCubit`).
final class RotateInitial implements RotateState {
  const RotateInitial();
}

final class RotateLoading implements RotateState {
  const RotateLoading();
}

final class RotateSuccess implements RotateState {
  const RotateSuccess({
    required this.rotatedBytes,
    required this.pageCount,
    required this.rotatedPageCount,
  });

  final Uint8List rotatedBytes;
  final int pageCount;
  final int rotatedPageCount;
}

final class RotateError implements RotateState {
  const RotateError({this.message = ''});
  final String message;
}
