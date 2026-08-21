import 'package:flutter/material.dart';

abstract class ThemeService extends ChangeNotifier {
  ThemeMode get themeMode;

  void toggleTheme();
}
