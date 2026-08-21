// Covers P2-2's progress indicator: percentage/status text, the
// reduced-motion branch (no shimmer ticking), and a width sweep matching
// `home_screen_responsive_test.dart`'s pattern.

import 'package:doclyvo/app/widgets/progress/progress_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  /// Pumps the indicator with `disableAnimations: true` so the shimmer
  /// never ticks — `pumpLocalized` ends in `pumpAndSettle`, which would
  /// never finish against a repeating `AnimationController`.
  Future<void> pumpIndicator(
    WidgetTester tester, {
    required double progress,
    String? label,
    String? hint,
    Size surfaceSize = kDesktopTestSurface,
  }) async {
    await pumpLocalized(
      tester,
      (context) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: ToolProgressIndicator(
              progress: progress,
              label: label,
              hint: hint,
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('shows the default status copy and percentage', (
    tester,
  ) async {
    await pumpIndicator(tester, progress: 42);

    expect(find.textContaining('İşleniyor...'), findsOneWidget);
    expect(find.textContaining('42%'), findsOneWidget);
    expect(find.text('Bu işlem birkaç saniye sürebilir.'), findsOneWidget);
  });

  testWidgets('renders a caller-supplied label and hint', (tester) async {
    await pumpIndicator(
      tester,
      progress: 58,
      label: 'Sıkıştırılıyor…',
      hint: 'Bu birkaç saniye sürebilir.',
    );

    expect(find.textContaining('Sıkıştırılıyor…'), findsOneWidget);
    expect(find.textContaining('58%'), findsOneWidget);
    expect(find.text('Bu birkaç saniye sürebilir.'), findsOneWidget);
  });

  testWidgets('clamps out-of-range progress to 0-100', (tester) async {
    await pumpIndicator(tester, progress: 140);

    expect(find.textContaining('100%'), findsOneWidget);
  });

  testWidgets('ticks the shimmer without throwing when motion is enabled', (
    tester,
  ) async {
    // Deliberately does not use `pumpLocalized`: it ends in
    // `pumpAndSettle`, which never finishes against a repeating
    // `AnimationController` — this test wants the shimmer *running*.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('tr', 'TR')],
          path: 'assets/translations',
          fallbackLocale: const Locale('tr', 'TR'),
          child: Builder(
            builder: (context) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const Scaffold(
                body: ToolProgressIndicator(progress: 50),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  const widths = <double>[
    360, 430, 699, 700, 800, 900, 1024, 1079, 1080, 1200, 1440, 1920,
  ];

  for (final width in widths) {
    testWidgets('lays out without overflowing at ${width}px', (tester) async {
      await pumpIndicator(
        tester,
        progress: 73,
        surfaceSize: Size(width, 400),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
