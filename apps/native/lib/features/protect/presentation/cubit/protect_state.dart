import 'dart:typed_data';

abstract class ProtectState {
  const ProtectState();
}

/// Before a protect action has run, or after a reset.
///
/// The selected file, the password, its reveal flag and the checked
/// permissions all live on the screen, not here — see `ProtectCubit` for why
/// (same reasoning as `WatermarkCubit`).
final class ProtectInitial implements ProtectState {
  const ProtectInitial();
}

final class ProtectLoading implements ProtectState {
  const ProtectLoading();
}

final class ProtectSuccess implements ProtectState {
  const ProtectSuccess({required this.protectedBytes, required this.pageCount});

  final Uint8List protectedBytes;
  final int pageCount;
}

final class ProtectError implements ProtectState {
  const ProtectError({this.message = ''});
  final String message;
}
