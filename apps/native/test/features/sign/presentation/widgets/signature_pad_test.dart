// The draw pad is the one control the screen sweep never reaches (that sweep
// pumps the empty state), and it is also the only place strokes are captured —
// so if its gesture plumbing is wrong, "Belgeye Yerleştir" silently has
// nothing to rasterize. Covered directly here.
//
// The pad does not own its strokes: the screen does, because it has to
// rasterize them. So the host here is a StatefulBuilder that setStates on
// every report, which is exactly what `_SignScreenState._onStrokesChanged`
// does. Each pointer move is followed by a `pump()` for the same reason: on a
// real device one move arrives per frame, so the pad always sees the strokes
// its previous report produced.

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/features/sign/presentation/widgets/signature_pad.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_harness.dart';

/// What a hosted pad reported back over the course of a test.
final class _PadRecorder {
  List<List<Offset>> strokes = const [];
  final List<Size> sizes = [];
}

void main() {
  setUpAll(initializeTestLocalization);

  Future<_PadRecorder> pumpPad(
    WidgetTester tester, {
    bool enabled = true,
    ScreenTier tier = ScreenTier.desktop,
    Size surfaceSize = const Size(380, 400),
    ThemeData? theme,
  }) async {
    final recorder = _PadRecorder();

    await pumpLocalized(
      tester,
      (context) => MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (_, setState) => SignaturePad(
              strokes: recorder.strokes,
              enabled: enabled,
              tier: tier,
              onStrokesChanged: (next, canvasSize) => setState(() {
                recorder.strokes = next;
                recorder.sizes.add(canvasSize);
              }),
            ),
          ),
        ),
      ),
      surfaceSize: surfaceSize,
    );

    return recorder;
  }

  /// Drags across the pad, one `pump()` per move so the pad rebuilds between
  /// pointer events the way it does on a device.
  Future<void> drag(
    WidgetTester tester, {
    required Offset from,
    required List<Offset> moves,
  }) async {
    final gesture = await tester.startGesture(from);
    await tester.pump();
    for (final move in moves) {
      await gesture.moveBy(move);
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
  }

  testWidgets('a drag reports one stroke with the pad size it was drawn in', (
    tester,
  ) async {
    final recorder = await pumpPad(tester);

    await drag(
      tester,
      from: tester.getCenter(find.byType(SignaturePad)),
      moves: const [Offset(20, 10)],
    );

    expect(recorder.strokes, hasLength(1));
    expect(recorder.strokes.single.length, greaterThanOrEqualTo(2));
    expect(recorder.sizes, isNotEmpty);
    expect(
      recorder.sizes.last.isEmpty,
      isFalse,
      reason: 'a zero-sized pad would make the rasterizer produce a 0x0 image',
    );
  });

  testWidgets('further drag points extend the last stroke, not a new one', (
    tester,
  ) async {
    final recorder = await pumpPad(tester);

    await drag(
      tester,
      from: tester.getCenter(find.byType(SignaturePad)),
      moves: const [Offset(10, 0), Offset(10, 5), Offset(10, -5)],
    );

    expect(recorder.strokes, hasLength(1));
    expect(recorder.strokes.single.length, greaterThanOrEqualTo(4));
  });

  testWidgets('a second drag starts a second stroke', (tester) async {
    final recorder = await pumpPad(tester);
    final center = tester.getCenter(find.byType(SignaturePad));

    for (final dy in const [-20.0, 20.0]) {
      await drag(
        tester,
        from: center + Offset(0, dy),
        moves: const [Offset(15, 0)],
      );
    }

    expect(recorder.strokes, hasLength(2));
  });

  testWidgets('a disabled pad reports nothing', (tester) async {
    final recorder = await pumpPad(tester, enabled: false);

    await drag(
      tester,
      from: tester.getCenter(find.byType(SignaturePad)),
      moves: const [Offset(30, 15)],
    );

    expect(recorder.strokes, isEmpty);
    expect(recorder.sizes, isEmpty);
  });

  testWidgets('the mobile tier gets the shorter pad the design draws', (
    tester,
  ) async {
    await pumpPad(tester, tier: ScreenTier.mobile);
    final mobileHeight = tester.getSize(find.byType(SignaturePad)).height;

    await pumpPad(tester);
    final desktopHeight = tester.getSize(find.byType(SignaturePad)).height;

    expect(mobileHeight, lessThan(desktopHeight));
  });

  testWidgets('lays out without overflowing at every tier and width', (
    tester,
  ) async {
    for (final tier in ScreenTier.values) {
      for (final width in const [360.0, 430.0, 700.0, 1440.0]) {
        await pumpPad(tester, tier: tier, surfaceSize: Size(width, 400));

        expect(
          tester.takeException(),
          isNull,
          reason: 'overflowed at ${width}px on ${tier.name}',
        );
      }
    }
  });

  testWidgets('renders in the dark theme without overflowing', (tester) async {
    await pumpPad(tester, theme: AppTheme.dark);

    expect(tester.takeException(), isNull);
  });
}
