// Guards the header's three tiers — mobile, compact desktop, full desktop —
// against the overflow the middle tier used to produce.

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/app/theme/theme_manager.dart';
import 'package:doclyvo/features/home/presentation/widgets/home_header.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  Future<void> pumpHeader(
    WidgetTester tester, {
    required double width,
  }) async {
    await pumpLocalized(
      tester,
      (context) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: HomeHeader(
            isMobile: width < ResponsiveConstants.mobileBreakpoint,
            themeService: ThemeManager(),
          ),
        ),
      ),
      surfaceSize: Size(width, 800),
    );
  }

  // Phone, the compact tier's two ends, and the design width. 1017px is the
  // full header's intrinsic width — the tier boundary has to sit above it.
  const widths = <double>[360, 700, 800, 1017, 1079, 1080, 1200, 1440];

  for (final width in widths) {
    testWidgets('lays out without overflowing at ${width}px', (tester) async {
      await pumpHeader(tester, width: width);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows the nav links only at or above the nav breakpoint', (
    tester,
  ) async {
    await pumpHeader(tester, width: ResponsiveConstants.headerNavBreakpoint);
    expect(find.text(LocaleKeys.home_navAllTools.tr()), findsOneWidget);
    expect(find.text(LocaleKeys.home_navSecurity.tr()), findsOneWidget);
  });

  testWidgets('drops the nav links on the compact tier but keeps the '
      'wordmark and theme toggle', (tester) async {
    await pumpHeader(tester, width: ResponsiveConstants.headerNavBreakpoint - 1);

    expect(find.text(LocaleKeys.home_navAllTools.tr()), findsNothing);
    expect(find.text(LocaleKeys.appName.tr()), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });

  testWidgets('drops the nav links on mobile too', (tester) async {
    await pumpHeader(tester, width: 360);

    expect(find.text(LocaleKeys.home_navAllTools.tr()), findsNothing);
    expect(find.text(LocaleKeys.appName.tr()), findsOneWidget);
  });
}
