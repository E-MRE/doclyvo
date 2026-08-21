// Guards the stale-`enabled` regression on Split. See
// test/helpers/upload_panel_loading_harness.dart for what it is and why the
// test drives the cubit directly instead of going through the UI flow.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/features/split/data/repositories/split_repository.dart';
import 'package:doclyvo/features/split/domain/models/split_result.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_cubit.dart';
import 'package:doclyvo/features/split/presentation/pages/split_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/upload_panel_loading_harness.dart';
import '../../../../helpers/widget_test_harness.dart';

/// A repository whose operation never completes, pinning the cubit in Loading.
final class _HangingSplitRepository implements SplitRepository {
  @override
  Future<int> readPageCount({required Uint8List bytes}) async => 3;

  @override
  Future<SplitResult> split({required Uint8List bytes}) =>
      Completer<SplitResult>().future;
}

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  testWidgets('upload panel locks down while a split is running', (
    tester,
  ) async {
    final cubit = SplitCubit(_HangingSplitRepository());
    await overrideDependency<SplitCubit>(() => cubit);

    await pumpToolScreen(tester, const SplitScreen());
    expect(
      tester.widget<UploadDropzone>(find.byType(UploadDropzone)).enabled,
      isTrue,
      reason: 'the dropzone should start interactive',
    );

    unawaited(cubit.split(bytes: Uint8List(0)));
    // Two frames: the first delivers the cubit's Loading event to the
    // BlocBuilder's stream subscription, the second paints the rebuild.
    await tester.pump();
    await tester.pump();

    expectDropzoneDisabled(tester);
  });
}
