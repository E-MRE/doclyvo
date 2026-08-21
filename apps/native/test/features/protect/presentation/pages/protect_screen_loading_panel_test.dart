// Guards the stale-`enabled` regression on Protect. See
// test/helpers/upload_panel_loading_harness.dart for what it is and why the
// test drives the cubit directly instead of going through the UI flow.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/features/protect/data/repositories/protect_repository.dart';
import 'package:doclyvo/features/protect/presentation/cubit/protect_cubit.dart';
import 'package:doclyvo/features/protect/presentation/pages/protect_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/upload_panel_loading_harness.dart';
import '../../../../helpers/widget_test_harness.dart';

/// A repository whose operation never completes, pinning the cubit in Loading.
final class _HangingProtectRepository implements ProtectRepository {
  @override
  Future<int> readPageCount({required Uint8List bytes}) async => 3;

  @override
  Future<Uint8List> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
  }) => Completer<Uint8List>().future;
}

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  testWidgets('upload panel locks down while a protect is running', (
    tester,
  ) async {
    final cubit = ProtectCubit(_HangingProtectRepository());
    await overrideDependency<ProtectCubit>(() => cubit);

    await pumpToolScreen(tester, const ProtectScreen());
    expect(
      tester.widget<UploadDropzone>(find.byType(UploadDropzone)).enabled,
      isTrue,
      reason: 'the dropzone should start interactive',
    );

    unawaited(cubit.protect(
      bytes: Uint8List(0),
      options: const PdfProtectionOptions(password: 'Doclyvo1!'),
      pageCount: 3,
    ));
    // Two frames: the first delivers the cubit's Loading event to the
    // BlocBuilder's stream subscription, the second paints the rebuild.
    await tester.pump();
    await tester.pump();

    expectDropzoneDisabled(tester);
  });
}
