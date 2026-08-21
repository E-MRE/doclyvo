import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';

/// The three opacity presets `design/Watermark.dc.html` offers, mapped onto
/// `PdfWatermarkOptions.opacity` (`0` invisible, `1` opaque) — the same
/// values `apps/web`'s watermark preview uses.
enum WatermarkOpacity {
  light,
  medium,
  strong;

  double get value => switch (this) {
    WatermarkOpacity.light => 0.18,
    WatermarkOpacity.medium => 0.35,
    WatermarkOpacity.strong => 0.55,
  };

  String get labelKey => switch (this) {
    WatermarkOpacity.light => LocaleKeys.watermark_opacityLight,
    WatermarkOpacity.medium => LocaleKeys.watermark_opacityMedium,
    WatermarkOpacity.strong => LocaleKeys.watermark_opacityStrong,
  };
}
