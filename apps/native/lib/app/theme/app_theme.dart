import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const accentColor = Color(0xFFDC4731);
    const surfaceColor = Color(0xFFFFFFFF);
    const textColor = Color(0xFF1D1D1F);
    const borderColor = Color(0xFFD2D2D7);
    const bgColor = Color(0xFFF5F5F7);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: accentColor,
        onPrimary: Color(0xFFFFFFFF),
        secondary: accentColor,
        onSecondary: Color(0xFFFFFFFF),
        tertiary: accentColor,
        onTertiary: Color(0xFFFFFFFF),
        surface: surfaceColor,
        onSurface: textColor,
        error: Colors.red,
        onError: Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: Sizes.typeH2,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusCard),
        ),
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: Sizes.typeDisplay,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineLarge: TextStyle(
          fontSize: Sizes.typeH1,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: Sizes.typeH2,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: Sizes.typeBody,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        labelMedium: TextStyle(
          fontSize: Sizes.typeLabel,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.lg,
          vertical: Sizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          borderSide: const BorderSide(
            color: accentColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const accentColor = Color(0xFFDC4731);
    const surfaceColor = Color(0xFF1C1C1E);
    const textColor = Color(0xFFF5F5F7);
    const borderColor = Color(0xFF38383A);
    const bgColor = Color(0xFF000000);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        onPrimary: Color(0xFF000000),
        secondary: accentColor,
        onSecondary: Color(0xFF000000),
        tertiary: accentColor,
        onTertiary: Color(0xFF000000),
        surface: surfaceColor,
        onSurface: textColor,
        error: Colors.red,
        onError: Color(0xFF000000),
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: Sizes.typeH2,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusCard),
        ),
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: Sizes.typeDisplay,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineLarge: TextStyle(
          fontSize: Sizes.typeH1,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: Sizes.typeH2,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: Sizes.typeBody,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        labelMedium: TextStyle(
          fontSize: Sizes.typeLabel,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.lg,
          vertical: Sizes.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          borderSide: const BorderSide(
            color: accentColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
