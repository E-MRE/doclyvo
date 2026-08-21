import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/generated/colors.gen.dart';
import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// The current [ScreenTier], derived from the window width. Widgets should
  /// read this (or [isMobile]/[isTablet]/[isDesktop]) instead of comparing
  /// `MediaQuery.sizeOf(context).width` against a breakpoint themselves.
  ScreenTier get screenTier =>
      ResponsiveConstants.tierForWidth(MediaQuery.sizeOf(this).width);

  bool get isMobile => screenTier == ScreenTier.mobile;

  bool get isTablet => screenTier == ScreenTier.tablet;

  bool get isDesktop => screenTier == ScreenTier.desktop;

  Color get textSoftColor =>
      isDarkMode ? ColorName.darkTextSoft : ColorName.lightTextSoft;

  Color get accentSoftColor =>
      isDarkMode ? ColorName.darkAccentSoft : ColorName.lightAccentSoft;

  Color get surfaceBorderColor =>
      isDarkMode ? ColorName.darkBorder : ColorName.lightBorder;
}
