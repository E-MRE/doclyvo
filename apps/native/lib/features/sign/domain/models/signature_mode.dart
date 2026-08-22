import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';

/// How the user produces the signature graphic, matching the design's three
/// tabs (Çiz / Yaz / Yükle) and `apps/web`'s `SignMode`.
///
/// All three end up as PNG bytes before they reach the engine — see
/// `SignatureImageRenderer`. `pdf_manipulator`'s only stamping primitive is
/// `addImageStamp`, so there is no "draw text into the PDF" path the way
/// `apps/api`'s reportlab overlay has; the typed mode rasterizes on-device
/// instead.
enum SignatureMode {
  /// Freehand strokes on an on-screen pad.
  draw(LocaleKeys.sign_modeDraw),

  /// A typed name, rendered to an image.
  type(LocaleKeys.sign_modeType),

  /// A PNG picked from the device.
  upload(LocaleKeys.sign_modeUpload);

  const SignatureMode(this.labelKey);

  /// `LocaleKeys` entry for this mode's tab label.
  final String labelKey;
}
