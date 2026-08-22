import 'dart:typed_data';

import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/sign/data/repositories/sign_repository.dart';
import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';
import 'package:doclyvo/features/sign/presentation/cubit/sign_state.dart';

/// Drives the Sign tool's async operations only.
///
/// The selected file, the active mode, the drawn strokes / typed name / picked
/// PNG and the page being signed all live in the screen's local state, not
/// here — same reasoning as `ProtectCubit`.
final class SignCubit extends BaseCubit<SignState> {
  SignCubit(this._repository) : super(const SignInitial());

  final SignRepository _repository;

  /// Reads the page count of a freshly-picked file, for the page selector and
  /// the result copy.
  ///
  /// Deliberately does not touch [SignState]: it is metadata, not the tool's
  /// action, so a failure here must not put the screen into an error state —
  /// same contract as `ProtectCubit.readPageCount`.
  Future<int?> readPageCount({required Uint8List bytes}) async {
    try {
      return await _repository.readPageCount(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  /// Stamps [signatureImageBytes] onto the page at [pageIndex] (zero-based).
  ///
  /// [pageCount] is display metadata for the result copy, not re-derived here.
  Future<void> sign({
    required Uint8List bytes,
    required Uint8List signatureImageBytes,
    required int pageIndex,
    required SignaturePlacement placement,
    required int pageCount,
  }) async {
    return safeCall<Uint8List>(
      action: () => _repository.sign(
        bytes: bytes,
        signatureImageBytes: signatureImageBytes,
        pageIndex: pageIndex,
        placement: placement,
      ),
      loadingState: const SignLoading(),
      successState: (data) => SignSuccess(
        signedBytes: data,
        pageCount: pageCount,
        signedPageNumber: pageIndex + 1,
      ),
      errorState: (message) => SignError(message: message),
    );
  }

  /// Back to the settings step, discarding the previous result/error.
  void reset() => safeEmit(const SignInitial());
}
