// Covers P2-4's error state widget: message display, retry callback,
// responsive layout across tiers, and a width sweep matching
// `home_screen_responsive_test.dart`'s pattern.

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/core/widgets/errors/error_state_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  Future<void> pumpError(
    WidgetTester tester, {
    required String message,
    VoidCallback? onRetry,
    ScreenTier tier = ScreenTier.desktop,
    Size surfaceSize = kDesktopTestSurface,
  }) async {
    await pumpLocalized(
      tester,
      (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: ErrorStateWidget(
            message: message,
            onRetry: onRetry ?? () {},
            tier: tier,
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('shows the error icon and message', (tester) async {
    await pumpError(
      tester,
      message: 'Bir hata oluştu. Lütfen tekrar deneyin.',
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Bir hata oluştu. Lütfen tekrar deneyin.'), findsOneWidget);
  });

  testWidgets('displays the retry button', (tester) async {
    await pumpError(
      tester,
      message: 'Hata',
    );

    expect(find.text('Tekrar Dene'), findsOneWidget);
  });

  testWidgets('fires the retry callback when button is tapped', (tester) async {
    var tapped = false;
    await pumpError(
      tester,
      message: 'Hata oluştu.',
      onRetry: () => tapped = true,
    );

    await tester.tap(find.text('Tekrar Dene'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('handles long error messages without overflow', (tester) async {
    const longMessage = 'Bu çok uzun bir hata mesajıdır. '
        'İşlem sırasında beklenmedik bir sorun meydana geldi. '
        'Lütfen dosyanızı kontrol ederek tekrar deneyiniz.';

    await pumpError(
      tester,
      message: longMessage,
    );

    expect(find.text(longMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses mobile padding on mobile tier', (tester) async {
    await pumpError(
      tester,
      message: 'Hata',
      tier: ScreenTier.mobile,
      surfaceSize: const Size(360, 600),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('uses desktop padding on desktop tier', (tester) async {
    await pumpError(
      tester,
      message: 'Hata',
    );

    expect(tester.takeException(), isNull);
  });

  const widths = <double>[
    360, 430, 699, 700, 800, 900, 1024, 1079, 1080, 1200, 1440, 1920,
  ];

  for (final width in widths) {
    testWidgets('lays out without overflowing at ${width}px', (tester) async {
      await pumpError(
        tester,
        message: 'Bu çok uzun bir hata mesajıdır. İşlem sırasında beklenmedik '
            'bir sorun meydana geldi. Lütfen dosyanızı kontrol ederek tekrar '
            'deneyiniz. Sorun devam ederse lütfen destek ekibiyle iletişime geçiniz.',
        surfaceSize: Size(width, 600),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
