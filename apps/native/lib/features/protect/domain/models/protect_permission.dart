import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';

/// The three restriction checkboxes `design/Protect.dc.html` offers.
///
/// Each value is a *restriction* — checking it takes a capability away — which
/// is why the labels read "…engelle" and why mapping onto
/// `PdfProtectionOptions` inverts them (`allowPrinting: !contains(noPrint)`).
/// Same enum-with-`LocaleKeys`-getters shape as `CompressQuality` and
/// `WatermarkOpacity`.
enum ProtectPermission {
  noPrint,
  noCopy,
  noEdit;

  String get labelKey => switch (this) {
    ProtectPermission.noPrint => LocaleKeys.protect_permissionNoPrint,
    ProtectPermission.noCopy => LocaleKeys.protect_permissionNoCopy,
    ProtectPermission.noEdit => LocaleKeys.protect_permissionNoEdit,
  };
}
