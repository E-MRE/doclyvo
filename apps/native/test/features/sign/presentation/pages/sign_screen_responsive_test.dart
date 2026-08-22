// Sweeps the Sign screen across the whole width range and fails on any
// RenderFlex overflow — the mandatory width sweep every new screen carries
// (see apps/native/CLAUDE.md's "mid-width overflow trap").
//
// It also pins the tier-dependent arrangement: only `desktop` puts the
// document panel and the signature panel side by side in an
// `IntrinsicHeight(Row(...))`; tablet and mobile stack them, the same
// "stack, don't squeeze" call the home screen made in P1-5.
//
// Note what this file cannot cover: the sweep only ever renders the *empty*
// state, so the signature pad, the preview and the progress indicator never
// appear here. Those live in the sibling loading-panel test and in
// test/features/sign/presentation/widgets/.

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/app/widgets/cards/app_card.dart';
import 'package:doclyvo/features/sign/presentation/pages/sign_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  /// Phone, both edges of the compact tablet tier, and the design width.
  const widths = <double>[
    360,
    430,
    699,
    700,
    800,
    900,
    1024,
    1079,
    1080,
    1200,
    1440,
    1920,
  ];

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
              return const SignScreen();
            },
          ),
        ),
        surfaceSize: Size(width, 900),
      );

      expect(tester.takeException(), isNull);

      final tier = ResponsiveConstants.tierForWidth(width);
      expect(reportedTier, tier);

      // The two panels are the screen's only `AppCard`s: the document panel
      // (dropzone + preview) and the signature/settings panel.
      final cards = find.byType(AppCard);
      expect(cards, findsNWidgets(2));
      final documentTopLeft = tester.getTopLeft(cards.at(0));
      final settingsTopLeft = tester.getTopLeft(cards.at(1));

      if (tier == ScreenTier.desktop) {
        expect(
          find.byType(IntrinsicHeight),
          findsOneWidget,
          reason: 'desktop should equalize the two columns with '
              'IntrinsicHeight(Row(...))',
        );
        expect(
          documentTopLeft.dx,
          lessThan(settingsTopLeft.dx),
          reason: 'desktop should place the document panel left of the '
              'signature panel',
        );
        expect(
          documentTopLeft.dy,
          settingsTopLeft.dy,
          reason: 'desktop columns should share a top edge',
        );
      } else {
        expect(
          find.byType(IntrinsicHeight),
          findsNothing,
          reason: '$tier stacks the panels, so there is no two-column row',
        );
        expect(
          documentTopLeft.dx,
          settingsTopLeft.dx,
          reason: '$tier should stack both panels at the same left edge',
        );
        expect(
          documentTopLeft.dy,
          lessThan(settingsTopLeft.dy),
          reason: '$tier should place the document panel above the '
              'signature panel',
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
        home: const SignScreen(),
      ),
      surfaceSize: const Size(800, 900),
    );

    expect(tester.takeException(), isNull);
  });
}
