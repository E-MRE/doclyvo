import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:doclyvo/features/watermark/data/repositories/watermark_repository.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_state.dart';

/// Drives the Watermark tool's async operations only.
///
/// The selected file, its preview thumbnail and the chosen text/position/
/// opacity settings all live in the screen's local state, not here — same
/// reasoning as `CompressCubit`/`RotateCubit`.
final class WatermarkCubit extends BaseCubit<WatermarkState> {
  WatermarkCubit(this._repository) : super(const WatermarkInitial());

  final WatermarkRepository _repository;

  /// Reads the page count of a freshly-picked file, for the result copy —
  /// deliberately does not touch [WatermarkState], same reasoning as
  /// `RotateCubit.readPageCount`.
  Future<int?> readPageCount({required Uint8List bytes}) async {
    try {
      return await _repository.readPageCount(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  /// Renders the first page for the live settings preview — `null` on
  /// failure, same "metadata, not the tool action" reasoning.
  Future<PdfPageThumbnail?> renderFirstPageThumbnail({
    required Uint8List bytes,
  }) async {
    try {
      return await _repository.renderFirstPageThumbnail(bytes: bytes);
    } on Exception {
      return null;
    }
  }

  /// Stamps every page of [bytes] per [options].
  ///
  /// [pageCount] is display metadata for the result copy, not re-derived
  /// here.
  Future<void> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
    required int pageCount,
  }) async {
    return safeCall<Uint8List>(
      action: () => _repository.addWatermark(bytes: bytes, options: options),
      loadingState: const WatermarkLoading(),
      successState: (data) =>
          WatermarkSuccess(watermarkedBytes: data, pageCount: pageCount),
      errorState: (message) => WatermarkError(message: message),
    );
  }

  /// Back to the settings step, discarding the previous result/error.
  void reset() => safeEmit(const WatermarkInitial());
}
