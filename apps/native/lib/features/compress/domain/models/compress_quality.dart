import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';

/// The three compression presets `design/Compress.dc.html` offers, mapped to
/// `PdfEngineService.compress`'s `imageQuality` (1 = smallest, 100 = best
/// quality) — the opposite direction from "compression strength", so `low`
/// compression keeps a high [imageQuality] and `high` compression keeps a low
/// one.
///
/// The `-20%`/`-58%`/`-82%` figures in the design are illustrative web-derived
/// numbers, not a guarantee `pdf_manipulator` reproduces exactly — actual
/// reduction depends on the source file's image content. They are kept as
/// static copy (not computed) because the real percentage is only known after
/// compressing, and `ResultPanel` already reports the real before/after sizes.
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

  /// Illustrative reduction figure shown next to the option, matching
  /// `design/Compress.dc.html`.
  String get illustrativePercent => switch (this) {
    CompressQuality.low => '-20%',
    CompressQuality.recommended => '-58%',
    CompressQuality.high => '-82%',
  };
}
