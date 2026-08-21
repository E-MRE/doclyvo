import 'dart:typed_data';

import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/compress/data/repositories/compress_repository.dart';
import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_state.dart';

/// Drives the Compress tool's async operation only.
///
/// The selected file and the chosen [CompressQuality] preset live in the
/// screen's local state, not here — `UploadDropzone`/`ResultPanel` are already
/// "controlled" widgets driven by their caller (see the P2-1/P2-3 Decisions
/// log entries), and `BaseCubit`'s 4-state pattern keeps `Initial`/`Loading`
/// free of fields. This cubit only tracks whether a compress call is running
/// and, once done, its result.
final class CompressCubit extends BaseCubit<CompressState> {
  CompressCubit(this._repository) : super(const CompressInitial());

  final CompressRepository _repository;

  Future<void> compress({
    required Uint8List bytes,
    required CompressQuality quality,
  }) async {
    return safeCall<Uint8List>(
      action: () => _repository.compress(bytes: bytes, quality: quality),
      loadingState: const CompressLoading(),
      successState: (data) => CompressSuccess(
        compressedBytes: data,
        originalSizeInBytes: bytes.length,
        compressedSizeInBytes: data.length,
      ),
      errorState: (message) => CompressError(message: message),
    );
  }

  /// Back to the settings step, discarding the previous result/error.
  void reset() => safeEmit(const CompressInitial());
}
