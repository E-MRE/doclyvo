/// The three widths the app lays screens out for.
///
/// `mobile` is below [ResponsiveConstants.mobileBreakpoint], `desktop` is at
/// or above [ResponsiveConstants.desktopBreakpoint], and `tablet` is
/// everything between — a resized desktop window, a landscape tablet, or a
/// split-view iPad. See `apps/native/CLAUDE.md`'s "mid-width overflow trap"
/// section for why this exists as a third value instead of a single bool.
enum ScreenTier { mobile, tablet, desktop }

final class ResponsiveConstants {
  const ResponsiveConstants._();

  static const double mobileBreakpoint = 700;

  /// Below this width the home header drops its nav links, and the app
  /// switches from the `tablet` tier to `desktop`.
  ///
  /// The full desktop header — logo, wordmark, five nav labels and the theme
  /// toggle — has an intrinsic width of ~1017px, so between
  /// [mobileBreakpoint] and here the desktop branch renders but cannot fit on
  /// one line. The extra headroom above 1017 absorbs longer translations and
  /// larger system text scales.
  static const double desktopBreakpoint = 1080;

  /// Classifies [width] into a [ScreenTier] using [mobileBreakpoint] and
  /// [desktopBreakpoint]. Widgets should read [ScreenTier] via
  /// `BuildContextExtension.screenTier` rather than comparing widths
  /// themselves.
  static ScreenTier tierForWidth(double width) {
    if (width < mobileBreakpoint) return ScreenTier.mobile;
    if (width < desktopBreakpoint) return ScreenTier.tablet;
    return ScreenTier.desktop;
  }
}
