import 'package:flutter/material.dart';

final class LocalizationConfig {
  const LocalizationConfig._();

  static const String path = 'assets/translations';
  static const Locale fallbackLocale = Locale('tr', 'TR');
  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'),
  ];
}
