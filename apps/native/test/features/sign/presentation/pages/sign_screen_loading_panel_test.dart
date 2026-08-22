// Guards the stale-`enabled` regression on Sign. See
// test/helpers/upload_panel_loading_harness.dart for what it is and why the
// test drives the cubit directly instead of going through the UI flow.
//
// Sign was written after P3A-7 found that bug, so it should have been immune
// from the start — this test is what makes that claim checkable rather than a
// comment. It also covers the second P3A-7 bug: the desktop layout is an
// `IntrinsicHeight(Row(...))`, and rendering the progress indicator inside it
// is exactly what used to throw "LayoutBuilder does not support returning
// intrinsic dimensions".

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/features/sign/data/repositories/sign_repository.dart';
import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';
import 'package:doclyvo/features/sign/presentation/cubit/sign_cubit.dart';
import 'package:doclyvo/features/sign/presentation/pages/sign_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/upload_panel_loading_harness.dart';
import '../../../../helpers/widget_test_harness.dart';

/// A repository whose operation never completes, pinning the cubit in Loading.
final class _HangingSignRepository implements SignRepository {
  @override
  Future<int> readPageCount({required Uint8List bytes}) async => 3;

  @override
  Future<Uint8List> sign({
    required Uint8List bytes,
    required Uint8List signatureImageBytes,
    required int pageIndex,
    required SignaturePlacement placement,
  }) => Completer<Uint8List>().future;
}

/// Starts a sign call that never finishes and lets the two frames the
/// BlocBuilder needs go by: the first delivers the Loading event to its stream
/// subscription, the second paints the rebuild.
Future<void> _startHangingSign(WidgetTester tester, SignCubit cubit) async {
  unawaited(
    cubit.sign(
      bytes: Uint8List(0),
      signatureImageBytes: Uint8List(0),
      pageIndex: 0,
      placement: SignaturePlacement.bottomRight,
      pageCount: 3,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  testWidgets('upload panel locks down while a sign is running', (
    tester,
  ) async {
    final cubit = SignCubit(_HangingSignRepository());
    await overrideDependency<SignCubit>(() => cubit);

    await pumpToolScreen(tester, const SignScreen());
    expect(
      tester.widget<UploadDropzone>(find.byType(UploadDropzone)).enabled,
      isTrue,
      reason: 'the dropzone should start interactive',
    );

    await _startHangingSign(tester, cubit);

    expectDropzoneDisabled(tester);
  });

  testWidgets('the desktop two-column layout survives a Loading emission', (
    tester,
  ) async {
    final cubit = SignCubit(_HangingSignRepository());
    await overrideDependency<SignCubit>(() => cubit);

    await pumpToolScreen(tester, const SignScreen());
    await _startHangingSign(tester, cubit);

    // No file is picked here, so the settings panel is still on its "pick a
    // file first" copy rather than the progress indicator — putting
    // `ToolProgressIndicator` itself inside the desktop
    // `IntrinsicHeight(Row(...))` is covered by
    // test/app/widgets/intrinsic_height_layout_test.dart. What this asserts is
    // that the two-column layout re-measures cleanly when the cubit emits
    // mid-flight, which is when the intrinsic-sizing crash used to surface.
    expect(find.byType(IntrinsicHeight), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
