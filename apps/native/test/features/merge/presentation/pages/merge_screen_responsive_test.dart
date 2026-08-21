// Sweeps the Merge screen across the whole width range and fails on any
// RenderFlex overflow — the same regression class the home, Compress and
// Split screens already guard against (see apps/native/CLAUDE.md's
// "mid-width overflow trap").

import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/features/merge/presentation/pages/merge_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  /// Phone, both edges of the compact desktop tier, and the design width.
  const widths = <double>[
    360,
    430,
    699,
    700,
    800,
    900,
    1024,
    1080,
    1200,
    1440,
    1920,
  ];

  for (final width in widths) {
    testWidgets('lays out without overflowing at ${width}px', (tester) async {
      await pumpLocalized(
        tester,
        (context) => MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const MergeScreen(),
        ),
        surfaceSize: Size(width, 900),
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders in the dark theme without overflowing', (
    tester,
  ) async {
    await pumpLocalized(
      tester,
      (context) => MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const MergeScreen(),
      ),
      surfaceSize: const Size(800, 900),
    );

    expect(tester.takeException(), isNull);
  });
}
