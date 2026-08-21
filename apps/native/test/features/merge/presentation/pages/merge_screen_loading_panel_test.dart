// Guards the stale-`enabled` regression on Merge. See
// test/helpers/upload_panel_loading_harness.dart for what it is and why the
// test drives the cubit directly instead of going through the UI flow.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/features/merge/data/repositories/merge_repository.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_cubit.dart';
import 'package:doclyvo/features/merge/presentation/pages/merge_screen.dart';
import 'package:doclyvo/features/merge/presentation/widgets/merge_file_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/upload_panel_loading_harness.dart';
import '../../../../helpers/widget_test_harness.dart';

/// A repository whose operation never completes, pinning the cubit in Loading.
final class _HangingMergeRepository implements MergeRepository {
  @override
  Future<int> readPageCount({required Uint8List bytes}) async => 3;

  @override
  Future<Uint8List> merge({required List<Uint8List> documents}) =>
      Completer<Uint8List>().future;
}

void main() {
  setUpAll(initializeTestLocalization);
  setUp(registerAppDependencies);
  tearDown(resetAppDependencies);

  testWidgets('file list panel locks down while a merge is running', (
    tester,
  ) async {
    final cubit = MergeCubit(_HangingMergeRepository());
    await overrideDependency<MergeCubit>(() => cubit);

    await pumpToolScreen(tester, const MergeScreen());
    expect(
      tester.widget<MergeFileList>(find.byType(MergeFileList)).enabled,
      isTrue,
      reason: 'the file list should start interactive',
    );

    unawaited(cubit.merge(documents: const [], fileCount: 2, totalPages: 6));
    // Two frames: the first delivers the cubit's Loading event to the
    // BlocBuilder's stream subscription, the second paints the rebuild.
    await tester.pump();
    await tester.pump();

    expectPanelDisabled(
      enabled: tester.widget<MergeFileList>(find.byType(MergeFileList)).enabled,
    );
  });
}
