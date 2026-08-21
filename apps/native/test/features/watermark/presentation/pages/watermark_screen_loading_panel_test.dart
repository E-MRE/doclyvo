// Guards the stale-`enabled` regression on Watermark. See
// test/helpers/upload_panel_loading_harness.dart for what it is and why the
// test drives the cubit directly instead of going through the UI flow.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/features/watermark/data/repositories/watermark_repository.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_cubit.dart';
import 'package:doclyvo/features/watermark/presentation/pages/watermark_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/upload_panel_loading_harness.dart';
import '../../../../helpers/widget_test_harness.dart';

/// A repository whose operation never completes, pinning the cubit in Loading.
final class _HangingWatermarkRepository implements WatermarkRepository {
  @override
  Future<int> readPageCount({required Uint8List bytes}) async => 3;

  @override
  Future<PdfPageThumbnail?> renderFirstPageThumbnail({
    required Uint8List bytes,
  }) async => null;

  @override
  Future<Uint8List> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
  }) => Completer<Uint8List>().future;
}

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  testWidgets('upload panel locks down while a watermark is running', (
    tester,
  ) async {
    final cubit = WatermarkCubit(_HangingWatermarkRepository());
    await overrideDependency<WatermarkCubit>(() => cubit);

    await pumpToolScreen(tester, const WatermarkScreen());
    expect(
      tester.widget<UploadDropzone>(find.byType(UploadDropzone)).enabled,
      isTrue,
      reason: 'the dropzone should start interactive',
    );

    unawaited(cubit.addWatermark(
      bytes: Uint8List(0),
      options: const PdfWatermarkOptions(text: 'TASLAK'),
      pageCount: 3,
    ));
    // Two frames: the first delivers the cubit's Loading event to the
    // BlocBuilder's stream subscription, the second paints the rebuild.
    await tester.pump();
    await tester.pump();

    expectDropzoneDisabled(tester);
  });
}
