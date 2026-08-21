import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:flutter/material.dart';

final class ThemeManager extends ThemeService {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
