// The lock badge is the only part of the Protect settings column the screen
// sweep never reaches — that sweep pumps the empty state, where no file is
// selected and the badge is not built. Cover it directly instead.

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/features/protect/presentation/widgets/protect_lock_status.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  Future<void> pumpBadge(
    WidgetTester tester, {
    required bool isProtected,
    required ScreenTier tier,
    required Size surfaceSize,
    ThemeData? theme,
  }) {
    return pumpLocalized(
      tester,
      (context) => MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: Center(
            child: ProtectLockStatus(isProtected: isProtected, tier: tier),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('shows the not-yet-protected status before encryption', (
    tester,
  ) async {
    await pumpBadge(
      tester,
      isProtected: false,
      tier: ScreenTier.desktop,
      surfaceSize: const Size(400, 400),
    );

    expect(find.text(LocaleKeys.protect_lockStatusIdle.tr()), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('flips to the protected status once encryption succeeded', (
    tester,
  ) async {
    await pumpBadge(
      tester,
      isProtected: true,
      tier: ScreenTier.desktop,
      surfaceSize: const Size(400, 400),
    );

    expect(find.text(LocaleKeys.protect_lockStatusDone.tr()), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  for (final tier in ScreenTier.values) {
    for (final width in <double>[280, 360, 700, 1440]) {
      testWidgets('lays out without overflowing at ${width}px on $tier', (
        tester,
      ) async {
        await pumpBadge(
          tester,
          isProtected: true,
          tier: tier,
          surfaceSize: Size(width, 400),
        );

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('renders in the dark theme without overflowing', (tester) async {
    await pumpBadge(
      tester,
      isProtected: false,
      tier: ScreenTier.mobile,
      surfaceSize: const Size(360, 400),
      theme: AppTheme.dark,
    );

    expect(tester.takeException(), isNull);
  });
}
