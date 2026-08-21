// Sweeps the home screen across the whole width range and fails on any
// RenderFlex overflow.
//
// Overflows here are invisible in a 1440px-wide manual check but very visible
// to a user with a resized desktop window or a landscape tablet, and Flutter
// reports them as errors rather than clipping quietly. Any new home widget
// should stay green here.

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/features/home/presentation/pages/home_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  /// Phone, both edges of the compact desktop tier, and the design width.
  const widths = <double>[360, 430, 699, 700, 800, 900, 1024, 1079, 1080, 1200,
    1440, 1920];

  for (final width in widths) {
    testWidgets('lays out without overflowing at ${width}px', (tester) async {
      ScreenTier? reportedTier;

      await pumpLocalized(
        tester,
        (context) => MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Builder(
            builder: (innerContext) {
              reportedTier = innerContext.screenTier;
              return const HomeScreen();
            },
          ),
        ),
        surfaceSize: Size(width, 900),
      );

      expect(tester.takeException(), isNull);
      expect(reportedTier, ResponsiveConstants.tierForWidth(width));
    });
  }

  testWidgets('renders in the dark theme without overflowing', (tester) async {
    await pumpLocalized(
      tester,
      (context) => MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const HomeScreen(),
      ),
      surfaceSize: const Size(800, 900),
    );

    expect(tester.takeException(), isNull);
  });
}
