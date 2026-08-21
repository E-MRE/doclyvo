// Guards a crash that every tool screen's desktop layout can trigger.
//
// Each screen puts its two panels in `IntrinsicHeight(Row(...))` to make the
// upload and settings cards the same height. `IntrinsicHeight` has to measure
// its children, and measuring a `LayoutBuilder` throws
// "LayoutBuilder does not support returning intrinsic dimensions" — so any
// shared panel widget that sized itself with one crashed the screen the moment
// it rendered. Both offenders (`ToolProgressIndicator`'s bar and
// `ResultPanel`'s size comparison) now use `FractionallySizedBox` instead.
//
// The existing per-screen width sweeps could not catch this: they pump the
// empty state, which shows neither the progress indicator nor the result
// panel.

import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/app/widgets/progress/progress_indicator.dart';
import 'package:doclyvo/app/widgets/result/result_panel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  /// Reproduces a tool screen's desktop two-column row around [panel].
  ///
  /// Deliberately does not `pumpAndSettle`: the progress bar's shimmer repeats
  /// forever, so settling would time out on a healthy widget.
  Future<void> pumpInIntrinsicHeightRow(
    WidgetTester tester,
    Widget panel, {
    ThemeData? theme,
  }) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('tr', 'TR')],
        path: 'assets/translations',
        fallbackLocale: const Locale('tr', 'TR'),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: theme ?? AppTheme.light,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: SingleChildScrollView(
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: SizedBox(height: 240)),
                      Expanded(child: panel),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('ToolProgressIndicator lays out inside an IntrinsicHeight row', (
    tester,
  ) async {
    await pumpInIntrinsicHeightRow(
      tester,
      const ToolProgressIndicator(progress: 60, label: 'İşleniyor…'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a fully-complete progress bar still lays out', (tester) async {
    await pumpInIntrinsicHeightRow(
      tester,
      const ToolProgressIndicator(progress: 100, label: 'İşleniyor…'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty progress bar still lays out', (tester) async {
    await pumpInIntrinsicHeightRow(
      tester,
      const ToolProgressIndicator(progress: 0, label: 'İşleniyor…'),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultPanel lays out inside an IntrinsicHeight row', (
    tester,
  ) async {
    await pumpInIntrinsicHeightRow(
      tester,
      ResultPanel(
        message: 'Belge korundu.',
        fileName: 'protected.pdf',
        pageCount: 18,
        // The size-comparison card is the part that used a LayoutBuilder, so
        // it has to be present for this test to mean anything.
        beforeSizeInBytes: 9000000,
        afterSizeInBytes: 3000000,
        onDownload: () {},
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ResultPanel lays out in the dark theme too', (tester) async {
    await pumpInIntrinsicHeightRow(
      tester,
      ResultPanel(
        message: 'Belge korundu.',
        fileName: 'protected.pdf',
        beforeSizeInBytes: 9000000,
        afterSizeInBytes: 3000000,
        onDownload: () {},
      ),
      theme: AppTheme.dark,
    );

    expect(tester.takeException(), isNull);
  });
}
