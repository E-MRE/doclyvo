// The screen sweep pumps the empty state, so the document panel's preview —
// page selector, placement slot, long file name — is never built by it. Cover
// it directly, at every tier and at the narrow widths the mid-width overflow
// trap lives at.

import 'dart:typed_data';

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/features/sign/presentation/widgets/sign_document_preview.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

/// A real 1x1 transparent PNG, so `Image.memory` decodes rather than falling
/// into its error builder.
final _pngBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

void main() {
  setUpAll(initializeTestLocalization);

  Future<void> pumpPreview(
    WidgetTester tester, {
    String fileName = 'sozlesme.pdf',
    int currentPage = 1,
    int? pageCount = 3,
    ValueChanged<int>? onPageChanged,
    Uint8List? signatureImageBytes,
    bool enabled = true,
    ScreenTier tier = ScreenTier.desktop,
    Size surfaceSize = const Size(1440, 900),
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
          body: SingleChildScrollView(
            child: SignDocumentPreview(
              fileName: fileName,
              currentPage: currentPage,
              pageCount: pageCount,
              onPageChanged: onPageChanged ?? (_) {},
              signatureImageBytes: signatureImageBytes,
              enabled: enabled,
              tier: tier,
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('shows the placement hint until a signature is placed', (
    tester,
  ) async {
    await pumpPreview(tester);

    expect(find.text(LocaleKeys.sign_placementHint.tr()), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('swaps the hint for the placed signature image', (tester) async {
    await pumpPreview(tester, signatureImageBytes: _pngBytes);

    expect(find.text(LocaleKeys.sign_placementHint.tr()), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders the page indicator for the current page', (
    tester,
  ) async {
    await pumpPreview(tester, currentPage: 2, pageCount: 7);

    expect(
      find.text(
        LocaleKeys.sign_pageIndicator.tr(
          namedArgs: {'current': '2', 'total': '7'},
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides the page selector while the page count is unknown', (
    tester,
  ) async {
    await pumpPreview(tester, pageCount: null);

    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('the previous arrow is dead on the first page and live after', (
    tester,
  ) async {
    final pages = <int>[];
    await pumpPreview(tester, onPageChanged: pages.add);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(pages, isEmpty, reason: 'page 1 has no previous page');

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(pages, [2]);
  });

  testWidgets('the next arrow is dead on the last page', (tester) async {
    final pages = <int>[];
    await pumpPreview(
      tester,
      currentPage: 3,
      pageCount: 3,
      onPageChanged: pages.add,
    );

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(pages, isEmpty, reason: 'the last page has no next page');

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(pages, [2]);
  });

  testWidgets('both arrows are dead while the tool is processing', (
    tester,
  ) async {
    final pages = <int>[];
    await pumpPreview(
      tester,
      currentPage: 2,
      onPageChanged: pages.add,
      enabled: false,
    );

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    expect(pages, isEmpty);
  });

  testWidgets('a very long file name is ellipsized instead of overflowing', (
    tester,
  ) async {
    await pumpPreview(
      tester,
      fileName: 'cok-uzun-bir-sozlesme-dosyasi-adi-${'x' * 120}.pdf',
      tier: ScreenTier.mobile,
      surfaceSize: const Size(360, 900),
    );

    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(find.textContaining('cok-uzun'));
    expect(name.overflow, TextOverflow.ellipsis);
    expect(name.maxLines, 1);
  });

  testWidgets('lays out without overflowing at every tier and width', (
    tester,
  ) async {
    for (final tier in ScreenTier.values) {
      for (final width in const [360.0, 430.0, 700.0, 1080.0, 1440.0]) {
        await pumpPreview(
          tester,
          tier: tier,
          surfaceSize: Size(width, 1200),
          signatureImageBytes: _pngBytes,
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at ${width}px on ${tier.name}',
        );
      }
    }
  });

  testWidgets('renders in the dark theme without overflowing', (tester) async {
    await pumpPreview(
      tester,
      tier: ScreenTier.mobile,
      surfaceSize: const Size(360, 900),
      theme: AppTheme.dark,
    );

    expect(tester.takeException(), isNull);
  });
}
