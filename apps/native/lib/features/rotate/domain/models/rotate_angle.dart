import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';

/// The three rotation presets `design/Rotate.dc.html` offers, applied to every
/// selected page at once via `PdfEngineService.rotatePages`'s clockwise-degree
/// map.
enum RotateAngle {
  clockwise90,
  flip180,
  counterClockwise90;

  /// Clockwise degrees to hand `PdfEngineService.rotatePages`.
  int get degrees => switch (this) {
    RotateAngle.clockwise90 => 90,
    RotateAngle.flip180 => 180,
    RotateAngle.counterClockwise90 => 270,
  };

  String get labelKey => switch (this) {
    RotateAngle.clockwise90 => LocaleKeys.rotate_angle90Label,
    RotateAngle.flip180 => LocaleKeys.rotate_angle180Label,
    RotateAngle.counterClockwise90 => LocaleKeys.rotate_angle270Label,
  };

  String get hintKey => switch (this) {
    RotateAngle.clockwise90 => LocaleKeys.rotate_angle90Hint,
    RotateAngle.flip180 => LocaleKeys.rotate_angle180Hint,
    RotateAngle.counterClockwise90 => LocaleKeys.rotate_angle270Hint,
  };
}
