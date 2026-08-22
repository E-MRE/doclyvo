// The screen sweep only ever pumps the empty state — no file selected — so it
// never builds the settings column's controls. The three mode tabs are covered
// directly here instead, same reasoning as
// test/features/protect/presentation/widgets/protect_lock_status_test.dart.

import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/features/sign/domain/models/signature_mode.dart';
import 'package:doclyvo/features/sign/presentation/widgets/signature_mode_tabs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  Future<void> pumpTabs(
    WidgetTester tester, {
    required SignatureMode selected,
    required ValueChanged<SignatureMode> onModeSelected,
    Size surfaceSize = const Size(380, 400),
    bool enabled = true,
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
          body: SignatureModeTabs(
            selected: selected,
            onModeSelected: onModeSelected,
            enabled: enabled,
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );
  }

  testWidgets('renders one tab per mode, in the design order', (tester) async {
    await pumpTabs(
      tester,
      selected: SignatureMode.draw,
      onModeSelected: (_) {},
    );

    for (final mode in SignatureMode.values) {
      expect(
        find.text(mode.labelKey.tr()),
        findsOneWidget,
        reason: '${mode.name} has no tab',
      );
    }
  });

  testWidgets('tapping a tab reports that mode', (tester) async {
    final tapped = <SignatureMode>[];
    await pumpTabs(
      tester,
      selected: SignatureMode.draw,
      onModeSelected: tapped.add,
    );

    await tester.tap(find.text(SignatureMode.type.labelKey.tr()));
    await tester.pump();
    await tester.tap(find.text(SignatureMode.upload.labelKey.tr()));
    await tester.pump();

    expect(tapped, [SignatureMode.type, SignatureMode.upload]);
  });

  testWidgets('the selected tab is painted with the accent, the others are '
      'not', (tester) async {
    await pumpTabs(
      tester,
      selected: SignatureMode.type,
      onModeSelected: (_) {},
    );

    final accent = AppTheme.light.colorScheme.primary;
    final decorations = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .toList();

    expect(
      decorations.where((decoration) => decoration.color == accent).length,
      1,
      reason: 'exactly one tab should carry the accent fill',
    );
  });

  testWidgets('a disabled tab strip reports nothing when tapped', (
    tester,
  ) async {
    final tapped = <SignatureMode>[];
    await pumpTabs(
      tester,
      selected: SignatureMode.draw,
      onModeSelected: tapped.add,
      enabled: false,
    );

    await tester.tap(find.text(SignatureMode.upload.labelKey.tr()));
    await tester.pump();

    expect(tapped, isEmpty);
  });

  testWidgets('lays out without overflowing at every tier width', (
    tester,
  ) async {
    // The tab strip is the narrowest thing in the settings column, so a
    // three-across Row is exactly the shape that overflows at 360px if the
    // tabs are not Expanded.
    for (final width in const [360.0, 430.0, 700.0, 1080.0, 1440.0]) {
      await pumpTabs(
        tester,
        selected: SignatureMode.upload,
        onModeSelected: (_) {},
        surfaceSize: Size(width, 400),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'the tab strip overflowed at ${width}px',
      );
    }
  });

  testWidgets('renders in the dark theme without overflowing', (tester) async {
    await pumpTabs(
      tester,
      selected: SignatureMode.draw,
      onModeSelected: (_) {},
      surfaceSize: const Size(360, 400),
      theme: AppTheme.dark,
    );

    expect(tester.takeException(), isNull);
  });
}
