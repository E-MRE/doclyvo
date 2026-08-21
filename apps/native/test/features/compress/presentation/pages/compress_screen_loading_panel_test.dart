// Locks in the "upload panel tracks Loading" invariant on Compress. See
// test/helpers/upload_panel_loading_harness.dart for what it is and why the
// test drives the cubit directly instead of going through the UI flow.
//
// Unlike the other five tool screens, Compress was never actually broken: its
// BlocConsumer listener starts a fake-progress ticker on Loading, and the
// ticker's setState re-runs build() — which recomputed `enabled` by accident.
// This test passes against the pre-fix source too. It is here so the invariant
// survives the day someone removes the ticker.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/features/compress/data/repositories/compress_repository.dart';
import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_cubit.dart';
import 'package:doclyvo/features/compress/presentation/pages/compress_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/upload_panel_loading_harness.dart';
import '../../../../helpers/widget_test_harness.dart';

/// A repository whose operation never completes, pinning the cubit in Loading.
final class _HangingCompressRepository implements CompressRepository {
  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    required CompressQuality quality,
  }) => Completer<Uint8List>().future;
}

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  testWidgets('upload panel locks down while a compress is running', (
    tester,
  ) async {
    final cubit = CompressCubit(_HangingCompressRepository());
    await overrideDependency<CompressCubit>(() => cubit);

    await pumpToolScreen(tester, const CompressScreen());
    expect(
      tester.widget<UploadDropzone>(find.byType(UploadDropzone)).enabled,
      isTrue,
      reason: 'the dropzone should start interactive',
    );

    unawaited(
      cubit.compress(
        bytes: Uint8List(0),
        quality: CompressQuality.recommended,
      ),
    );
    // Two frames: the first delivers the cubit's Loading event to the
    // BlocBuilder's stream subscription, the second paints the rebuild.
    await tester.pump();
    await tester.pump();

    expectDropzoneDisabled(tester);
  });
}
