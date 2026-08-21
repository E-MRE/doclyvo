import 'dart:typed_data';

abstract class ReorderState {
  const ReorderState();
}

/// Before a reorder action has run, or after a reset.
///
/// The selected file and its page order both live on the screen, not here —
/// see `ReorderCubit` for why (same reasoning as `RotateCubit`).
final class ReorderInitial implements ReorderState {
  const ReorderInitial();
}

final class ReorderLoading implements ReorderState {
  const ReorderLoading();
}

final class ReorderSuccess implements ReorderState {
  const ReorderSuccess({required this.reorderedBytes, required this.pageCount});

  final Uint8List reorderedBytes;
  final int pageCount;
}

final class ReorderError implements ReorderState {
  const ReorderError({this.message = ''});
  final String message;
}
