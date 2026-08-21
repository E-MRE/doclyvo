import 'dart:typed_data';

abstract class WatermarkState {
  const WatermarkState();
}

/// Before an add-watermark action has run, or after a reset.
///
/// The selected file, its preview and the chosen settings all live on the
/// screen, not here — see `WatermarkCubit` for why (same reasoning as
/// `CompressCubit`).
final class WatermarkInitial implements WatermarkState {
  const WatermarkInitial();
}

final class WatermarkLoading implements WatermarkState {
  const WatermarkLoading();
}

final class WatermarkSuccess implements WatermarkState {
  const WatermarkSuccess({required this.watermarkedBytes, required this.pageCount});

  final Uint8List watermarkedBytes;
  final int pageCount;
}

final class WatermarkError implements WatermarkState {
  const WatermarkError({this.message = ''});
  final String message;
}
