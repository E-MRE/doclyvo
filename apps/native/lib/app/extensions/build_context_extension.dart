import 'package:doclyvo/generated/colors.gen.dart';
import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get textSoftColor =>
      isDarkMode ? ColorName.darkTextSoft : ColorName.lightTextSoft;

  Color get accentSoftColor =>
      isDarkMode ? ColorName.darkAccentSoft : ColorName.lightAccentSoft;

  Color get surfaceBorderColor =>
      isDarkMode ? ColorName.darkBorder : ColorName.lightBorder;
}
