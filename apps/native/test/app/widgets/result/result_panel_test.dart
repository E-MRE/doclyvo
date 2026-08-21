// Covers P2-3's result panel: the success copy, the conditional before/after
// comparison, the conditional auto-delete notice, and a width sweep matching
// `home_screen_responsive_test.dart`'s pattern.

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/widgets/result/result_panel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  Future<void> pumpPanel(
    WidgetTester tester, {
    required String message,
    required String fileName,
    VoidCallback? onDownload,
    int? pageCount,
    int? beforeSizeInBytes,
    int? afterSizeInBytes,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    bool showAutoDeleteNotice = false,
    ScreenTier tier = ScreenTier.desktop,
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
            body: SingleChildScrollView(
              child: ResultPanel(
                message: message,
                fileName: fileName,
                onDownload: onDownload ?? () {},
                pageCount: pageCount,
                beforeSizeInBytes: beforeSizeInBytes,
                afterSizeInBytes: afterSizeInBytes,
                secondaryActionLabel: secondaryActionLabel,
                onSecondaryAction: onSecondaryAction,
                showAutoDeleteNotice: showAutoDeleteNotice,
                tier: tier,
              ),
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('shows the heading, message and file name', (tester) async {
    await pumpPanel(
      tester,
      message: 'rapor-2024.pdf sıkıştırıldı ve indirilmeye hazır.',
      fileName: 'rapor-2024-sikistirilmis.pdf',
    );

    expect(find.text('Dosyan hazır'), findsOneWidget);
    expect(
      find.text('rapor-2024.pdf sıkıştırıldı ve indirilmeye hazır.'),
      findsOneWidget,
    );
    expect(find.text('rapor-2024-sikistirilmis.pdf'), findsOneWidget);
  });

  testWidgets('shows the page count only when supplied', (tester) async {
    await pumpPanel(
      tester,
      message: 'hazır',
      fileName: 'a.pdf',
      pageCount: 18,
    );

    expect(find.text('18 sayfa'), findsOneWidget);
  });

  testWidgets('does not show the comparison card when sizes are omitted', (
    tester,
  ) async {
    await pumpPanel(tester, message: 'hazır', fileName: 'a.pdf');

    expect(find.text('Orijinal Boyut'), findsNothing);
    expect(find.text('Yeni Boyut'), findsNothing);
  });

  testWidgets('shows the before/after comparison with a reduction percent', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      message: 'hazır',
      fileName: 'a.pdf',
      beforeSizeInBytes: 9016524, // ~8.6 MB
      afterSizeInBytes: 3774874, // ~3.6 MB
    );

    expect(find.text('Orijinal Boyut'), findsOneWidget);
    expect(find.text('Yeni Boyut'), findsOneWidget);
    expect(find.text('8.6 MB'), findsOneWidget);
    expect(find.textContaining('3.6 MB · -58%'), findsOneWidget);
  });

  testWidgets('shows a growth percent with a plus sign when the file grew', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      message: 'hazır',
      fileName: 'a.pdf',
      beforeSizeInBytes: 1000,
      afterSizeInBytes: 1500,
    );

    expect(find.textContaining('+50%'), findsOneWidget);
  });

  testWidgets('fires onDownload when the download button is tapped', (
    tester,
  ) async {
    var tapped = false;
    await pumpPanel(
      tester,
      message: 'hazır',
      fileName: 'a.pdf',
      onDownload: () => tapped = true,
    );

    await tester.tap(find.text('İndir'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('shows an optional secondary action and fires its callback', (
    tester,
  ) async {
    var tapped = false;
    await pumpPanel(
      tester,
      message: 'hazır',
      fileName: 'a.pdf',
      secondaryActionLabel: 'Bağlantıyı Kopyala',
      onSecondaryAction: () => tapped = true,
    );

    expect(find.text('Bağlantıyı Kopyala'), findsOneWidget);
    await tester.tap(find.text('Bağlantıyı Kopyala'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('hides the auto-delete notice by default', (tester) async {
    await pumpPanel(tester, message: 'hazır', fileName: 'a.pdf');

    expect(
      find.text('Dosya 24 saat sonra otomatik olarak silinecektir'),
      findsNothing,
    );
  });

  testWidgets('shows the auto-delete notice when requested', (tester) async {
    await pumpPanel(
      tester,
      message: 'hazır',
      fileName: 'a.pdf',
      showAutoDeleteNotice: true,
    );

    expect(
      find.text('Dosya 24 saat sonra otomatik olarak silinecektir'),
      findsOneWidget,
    );
  });

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
      final tier = ResponsiveConstants.tierForWidth(width);

      await pumpPanel(
        tester,
        message: 'rapor-2024.pdf sıkıştırıldı ve indirilmeye hazır.',
        fileName: 'rapor-2024-sikistirilmis-uzun-bir-dosya-adi.pdf',
        pageCount: 18,
        beforeSizeInBytes: 9016524,
        afterSizeInBytes: 3774874,
        secondaryActionLabel: 'Bağlantıyı Kopyala',
        onSecondaryAction: () {},
        showAutoDeleteNotice: true,
        tier: tier,
        surfaceSize: Size(width, 900),
      );

      expect(tester.takeException(), isNull);
    });
  }
}
