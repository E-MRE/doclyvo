import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';

/// The three compression presets `design/Compress.dc.html` offers, mapped to
/// `PdfEngineService.compress`'s `imageQuality` (1 = smallest, 100 = best
/// quality) — the opposite direction from "compression strength", so `low`
/// compression keeps a high [imageQuality] and `high` compression keeps a low
/// one.
///
/// `design/Compress.dc.html` prints a `-20%`/`-58%`/`-82%` figure next to each
/// preset. Those are illustrative web-derived numbers, and the real reduction
/// depends entirely on how much raster image data the source file carries —
/// `pdf_manipulator` compresses embedded images, so a text-only PDF barely
/// moves whichever preset is picked. Showing a number the tool cannot honour is
/// worse than showing none, and the number is genuinely unknowable before the
/// file is processed, so the presets carry no percentage at all. The real
/// before/after sizes are reported afterwards by `ResultPanel`.
enum CompressQuality {
  low,
  recommended,
  high;

  /// `pdf_manipulator`'s `imageQuality` for this preset.
  int get imageQuality => switch (this) {
    CompressQuality.low => 85,
    CompressQuality.recommended => 60,
    CompressQuality.high => 30,
  };

  String get titleKey => switch (this) {
    CompressQuality.low => LocaleKeys.compress_qualityLowTitle,
    CompressQuality.recommended => LocaleKeys.compress_qualityRecommendedTitle,
    CompressQuality.high => LocaleKeys.compress_qualityHighTitle,
  };

  String get hintKey => switch (this) {
    CompressQuality.low => LocaleKeys.compress_qualityLowHint,
    CompressQuality.recommended => LocaleKeys.compress_qualityRecommendedHint,
    CompressQuality.high => LocaleKeys.compress_qualityHighHint,
  };
}
