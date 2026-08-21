import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/protect/data/repositories/protect_repository.dart';
import 'package:doclyvo/features/protect/presentation/cubit/protect_state.dart';

/// Drives the Protect tool's async operations only.
///
/// The selected file, the password and the checked permissions all live in the
/// screen's local state, not here — same reasoning as `WatermarkCubit`. The
/// password in particular never enters a state object, so it cannot leak into
/// a `BlocObserver` log or an error-state message.
final class ProtectCubit extends BaseCubit<ProtectState> {
  ProtectCubit(this._repository) : super(const ProtectInitial());

  final ProtectRepository _repository;

  /// Reads the page count of a freshly-picked file, for the result copy —
  /// deliberately does not touch [ProtectState], same reasoning as
  /// `WatermarkCubit.readPageCount`: it is metadata, not the tool's action, so
  /// a failure here must not put the screen into an error state.
  Future<int?> readPageCount({required Uint8List bytes}) async {
    try {
      return await _repository.readPageCount(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  /// Encrypts [bytes] per [options].
  ///
  /// [pageCount] is display metadata for the result copy, not re-derived here.
  Future<void> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
    required int pageCount,
  }) async {
    return safeCall<Uint8List>(
      action: () => _repository.protect(bytes: bytes, options: options),
      loadingState: const ProtectLoading(),
      successState: (data) =>
          ProtectSuccess(protectedBytes: data, pageCount: pageCount),
      errorState: (message) => ProtectError(message: message),
    );
  }

  /// Back to the settings step, discarding the previous result/error.
  void reset() => safeEmit(const ProtectInitial());
}
