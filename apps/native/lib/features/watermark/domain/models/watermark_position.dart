import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';

/// The three position presets `design/Watermark.dc.html` offers, mapped onto
/// `PdfWatermarkOptions`'s `placement`/`rotation` pair — the engine has no
/// dedicated "diagonal" placement, so that preset is a centered placement
/// with a rotation applied instead, matching `apps/web`'s
/// `rotate(-30deg)` preview transform.
enum WatermarkPosition {
  center,
  diagonal,
  corner;

  PdfWatermarkPlacement get placement => switch (this) {
    WatermarkPosition.center => PdfWatermarkPlacement.center,
    WatermarkPosition.diagonal => PdfWatermarkPlacement.center,
    WatermarkPosition.corner => PdfWatermarkPlacement.bottomRight,
  };

  double get rotation => switch (this) {
    WatermarkPosition.center => 0,
    WatermarkPosition.diagonal => -30,
    WatermarkPosition.corner => 0,
  };

  String get labelKey => switch (this) {
    WatermarkPosition.center => LocaleKeys.watermark_positionCenter,
    WatermarkPosition.diagonal => LocaleKeys.watermark_positionDiagonal,
    WatermarkPosition.corner => LocaleKeys.watermark_positionCorner,
  };
}
