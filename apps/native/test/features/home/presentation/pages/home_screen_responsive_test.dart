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
import 'package:doclyvo/features/home/presentation/widgets/home_hero_section.dart';
import 'package:doclyvo/features/home/presentation/widgets/upload_preview_card.dart';
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
      final tier = ResponsiveConstants.tierForWidth(width);
      expect(reportedTier, tier);

      // Tablet stacks the hero above the upload card full-width, like
      // mobile — only desktop puts them side by side in a Row. See the
      // P1-5 Decisions log entry in NATIVE-TASKS.md.
      final heroTopLeft = tester.getTopLeft(find.byType(HomeHeroSection));
      final uploadTopLeft = tester.getTopLeft(
        find.byType(UploadPreviewCard),
      );
      if (tier == ScreenTier.desktop) {
        expect(
          heroTopLeft.dx,
          lessThan(uploadTopLeft.dx),
          reason: 'desktop should place the hero and upload card side by '
              'side',
        );
      } else {
        expect(
          heroTopLeft.dx,
          uploadTopLeft.dx,
          reason: '$tier should stack the hero above the upload card at '
              'the same left edge',
        );
        expect(
          heroTopLeft.dy,
          lessThan(uploadTopLeft.dy),
          reason: '$tier should place the hero above the upload card',
        );
      }
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
