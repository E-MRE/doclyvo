import 'dart:typed_data';

abstract class SignState {
  const SignState();
}

/// Before a sign action has run, or after a reset.
///
/// The selected file, the mode, the strokes/typed text/picked image and the
/// placed signature all live on the screen, not here — same reasoning as
/// `ProtectCubit`/`WatermarkCubit`: the house convention keeps
/// `Initial`/`Loading` fieldless, so in-progress editing state cannot be
/// half-carried by a state object.
final class SignInitial implements SignState {
  const SignInitial();
}

final class SignLoading implements SignState {
  const SignLoading();
}

final class SignSuccess implements SignState {
  const SignSuccess({
    required this.signedBytes,
    required this.pageCount,
    required this.signedPageNumber,
  });

  final Uint8List signedBytes;
  final int pageCount;

  /// One-based page the signature landed on, for the result copy.
  final int signedPageNumber;
}

final class SignError implements SignState {
  const SignError({this.message = ''});
  final String message;
}
