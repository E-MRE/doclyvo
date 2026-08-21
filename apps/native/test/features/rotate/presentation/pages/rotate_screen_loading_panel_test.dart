// Guards the stale-`enabled` regression on Rotate. See
// test/helpers/upload_panel_loading_harness.dart for what it is and why the
// test drives the cubit directly instead of going through the UI flow.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/features/rotate/data/repositories/rotate_repository.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_cubit.dart';
import 'package:doclyvo/features/rotate/presentation/pages/rotate_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/upload_panel_loading_harness.dart';
import '../../../../helpers/widget_test_harness.dart';

/// A repository whose operation never completes, pinning the cubit in Loading.
final class _HangingRotateRepository implements RotateRepository {
  @override
  Future<int> readPageCount({required Uint8List bytes}) async => 3;

  @override
  Stream<PdfPageThumbnail> renderThumbnails({required Uint8List bytes}) =>
      const Stream<PdfPageThumbnail>.empty();

  @override
  Future<Uint8List> rotatePages({
    required Uint8List bytes,
    required Map<int, int> pageRotations,
  }) => Completer<Uint8List>().future;
}

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  testWidgets('upload panel locks down while a rotate is running', (
    tester,
  ) async {
    final cubit = RotateCubit(_HangingRotateRepository());
    await overrideDependency<RotateCubit>(() => cubit);

    await pumpToolScreen(tester, const RotateScreen());
    expect(
      tester.widget<UploadDropzone>(find.byType(UploadDropzone)).enabled,
      isTrue,
      reason: 'the dropzone should start interactive',
    );

    unawaited(cubit.rotate(
      bytes: Uint8List(0),
      pageRotations: const {0: 90},
      pageCount: 3,
      rotatedPageCount: 1,
    ));
    // Two frames: the first delivers the cubit's Loading event to the
    // BlocBuilder's stream subscription, the second paints the rebuild.
    await tester.pump();
    await tester.pump();

    expectDropzoneDisabled(tester);
  });
}
