import 'dart:typed_data';

abstract class CompressState {
  const CompressState();
}

/// Before a compress action has run, or after a reset.
///
/// The selected file and chosen quality preset are owned by the screen, not
/// this state — see `CompressCubit` for why.
final class CompressInitial implements CompressState {
  const CompressInitial();
}

final class CompressLoading implements CompressState {
  const CompressLoading();
}

final class CompressSuccess implements CompressState {
  const CompressSuccess({
    required this.compressedBytes,
    required this.originalSizeInBytes,
    required this.compressedSizeInBytes,
  });

  final Uint8List compressedBytes;
  final int originalSizeInBytes;
  final int compressedSizeInBytes;
}

final class CompressError implements CompressState {
  const CompressError({this.message = ''});
  final String message;
}
