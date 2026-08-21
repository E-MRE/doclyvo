final class ResponsiveConstants {
  const ResponsiveConstants._();

  static const double mobileBreakpoint = 700;

  /// Below this width the home header drops its nav links.
  ///
  /// The full desktop header — logo, wordmark, five nav labels and the theme
  /// toggle — has an intrinsic width of ~1017px, so between
  /// [mobileBreakpoint] and here the desktop branch renders but cannot fit on
  /// one line. The extra headroom above 1017 absorbs longer translations and
  /// larger system text scales.
  static const double headerNavBreakpoint = 1080;
}
