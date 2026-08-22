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
// The same trap has a second shape, found from a desktop run of Rotate/Split/
// Reorder: a shrink-wrapped `GridView` is a viewport, and a viewport answers an
// intrinsic query by tripping `debugThrowIfNotCheckingIntrinsics()`. Each page
// grid sits in the left panel and only appears once a file is picked, so the
// screens crashed exactly then. All three now lay out with `TileGrid`.
//
// The existing per-screen width sweeps could not catch this: they pump the
// empty state, which shows neither the progress indicator, the result panel,
// nor a page grid.

import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/app/widgets/layout/tile_grid.dart';
import 'package:doclyvo/app/widgets/progress/progress_indicator.dart';
import 'package:doclyvo/app/widgets/result/result_panel.dart';
import 'package:doclyvo/features/reorder/domain/models/reorder_page_entry.dart';
import 'package:doclyvo/features/reorder/presentation/widgets/reorder_page_grid.dart';
import 'package:doclyvo/features/rotate/domain/models/rotate_angle.dart';
import 'package:doclyvo/features/rotate/domain/models/rotate_page_entry.dart';
import 'package:doclyvo/features/rotate/presentation/widgets/rotate_page_grid.dart';
import 'package:doclyvo/features/split/presentation/widgets/split_page_grid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  /// Reproduces a tool screen's desktop two-column row around [panel].
  ///
  /// Goes through `pumpLocalized` rather than hand-rolling
  /// `pumpWidget(EasyLocalization(...))`. That is not a style preference: with
  /// the hand-rolled version only the first test in a file ever got past
  /// `EasyLocalization`'s asset load, so every later test pumped a tree with
  /// no [panel] in it and its `takeException()` assertion passed vacuously —
  /// which is exactly why this file did not catch the page grids. See the
  /// warning in `apps/native/CLAUDE.md` about the translation asset loading
  /// off the real event loop.
  ///
  /// Deliberately does not `pumpAndSettle`: the progress bar's shimmer repeats
  /// forever, so settling would time out on a healthy widget. [expectPanel] is
  /// asserted instead, so a tree that failed to build fails the test loudly.
  Future<void> pumpInIntrinsicHeightRow(
    WidgetTester tester,
    Widget panel, {
    required Finder expectPanel,
    ThemeData? theme,
  }) async {
    await pumpLocalized(
      tester,
      (context) => MaterialApp(
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
      surfaceSize: const Size(1440, 900),
      settle: false,
    );

    expect(
      expectPanel,
      findsWidgets,
      reason: 'the panel never rendered, so this test would prove nothing',
    );
  }

  testWidgets('ToolProgressIndicator lays out inside an IntrinsicHeight row', (
    tester,
  ) async {
    await pumpInIntrinsicHeightRow(
      tester,
      const ToolProgressIndicator(progress: 60, label: 'İşleniyor…'),
      expectPanel: find.byType(ToolProgressIndicator),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a fully-complete progress bar still lays out', (tester) async {
    await pumpInIntrinsicHeightRow(
      tester,
      const ToolProgressIndicator(progress: 100, label: 'İşleniyor…'),
      expectPanel: find.byType(ToolProgressIndicator),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty progress bar still lays out', (tester) async {
    await pumpInIntrinsicHeightRow(
      tester,
      const ToolProgressIndicator(progress: 0, label: 'İşleniyor…'),
      expectPanel: find.byType(ToolProgressIndicator),
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
      expectPanel: find.byType(ResultPanel),
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
      expectPanel: find.byType(ResultPanel),
    );

    expect(tester.takeException(), isNull);
  });

  // ── The page grids ────────────────────────────────────────────────────────
  //
  // These are the widgets that actually crashed on a desktop run: all three
  // used a shrink-wrapped `GridView`, which cannot be measured. They render in
  // the left panel of the very same row, so this is the exact failing shape.

  testWidgets('RotatePageGrid lays out inside an IntrinsicHeight row', (
    tester,
  ) async {
    await pumpInIntrinsicHeightRow(
      tester,
      RotatePageGrid(
        // 8 pages over 6 columns: two rows, the second one short, which is
        // where the padding cells matter.
        entries: List.generate(8, (i) => RotatePageEntry(pageIndex: i)),
        angle: RotateAngle.clockwise90,
        onToggleEntry: (_) {},
        onToggleAll: (_) {},
      ),
      expectPanel: find.byType(RotatePageGrid),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ReorderPageGrid lays out inside an IntrinsicHeight row', (
    tester,
  ) async {
    await pumpInIntrinsicHeightRow(
      tester,
      ReorderPageGrid(
        entries: List.generate(7, (i) => ReorderPageEntry(pageIndex: i)),
        onMoveLeft: (_) {},
        onMoveRight: (_) {},
      ),
      expectPanel: find.byType(ReorderPageGrid),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('SplitPageGrid lays out inside an IntrinsicHeight row', (
    tester,
  ) async {
    await pumpInIntrinsicHeightRow(
      tester,
      const SplitPageGrid(pageCount: 9),
      expectPanel: find.byType(SplitPageGrid),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a single-page grid lays out inside an IntrinsicHeight row', (
    tester,
  ) async {
    // One tile in a 6-column grid is five padding cells wide — the degenerate
    // case for `TileGrid`'s last-row padding.
    await pumpInIntrinsicHeightRow(
      tester,
      const SplitPageGrid(pageCount: 1),
      expectPanel: find.byType(SplitPageGrid),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('TileGrid keeps every tile one column wide', (tester) async {
    // The point of padding the last row: without it the two tiles below would
    // stretch to half the row each instead of staying a sixth of it.
    await pumpInIntrinsicHeightRow(
      tester,
      const TileGrid(
        crossAxisCount: 6,
        childAspectRatio: 1,
        children: [
          SizedBox(key: Key('a')),
          SizedBox(key: Key('b')),
        ],
      ),
      expectPanel: find.byType(TileGrid),
    );

    final row = tester.getSize(find.byType(TileGrid)).width;
    final tile = tester.getSize(find.byKey(const Key('a'))).width;

    expect(tile, closeTo(tester.getSize(find.byKey(const Key('b'))).width, 0.5));
    expect(
      tile,
      lessThan(row / 5),
      reason: 'a tile in a 6-column grid must not stretch past its column',
    );
  });
}
