// Covers MergeCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, reset() returning to Initial, and the
// non-emitting readPageCount() passthrough — the 4-state pattern every
// BaseCubit subclass follows, plus the one extra passthrough Merge needs
// for its per-row page-count summary (same shape as Split's).

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/features/merge/data/repositories/merge_repository.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_cubit.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeMergeRepository implements MergeRepository {
  _FakeMergeRepository({this.mergedBytes, this.error, this.pageCount});

  final Uint8List? mergedBytes;
  final Exception? error;
  final int? pageCount;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final error = this.error;
    if (error != null) throw error;
    return pageCount!;
  }

  @override
  Future<Uint8List> merge({required List<Uint8List> documents}) async {
    final error = this.error;
    if (error != null) throw error;
    return mergedBytes!;
  }
}

void main() {
  final documentA = Uint8List.fromList(List.filled(4, 1));
  final documentB = Uint8List.fromList(List.filled(6, 2));
  final mergedBytes = Uint8List.fromList(List.filled(10, 3));

  test('starts in MergeInitial', () {
    final cubit = MergeCubit(_FakeMergeRepository());
    expect(cubit.state, isA<MergeInitial>());
    unawaited(cubit.close());
  });

  test('emits Loading then Success with the merged bytes and counts', () async {
    final cubit = MergeCubit(_FakeMergeRepository(mergedBytes: mergedBytes));
    final states = <MergeState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.merge(
      documents: [documentA, documentB],
      fileCount: 2,
      totalPages: 7,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<MergeLoading>());
    final success = states[1] as MergeSuccess;
    expect(success.mergedBytes, same(mergedBytes));
    expect(success.fileCount, 2);
    expect(success.totalPages, 7);

    await subscription.cancel();
    await cubit.close();
  });

  test('emits Loading then Error when the repository throws', () async {
    final cubit = MergeCubit(
      _FakeMergeRepository(
        error: const PdfEngineException('corrupted document'),
      ),
    );
    final states = <MergeState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.merge(
      documents: [documentA],
      fileCount: 1,
      totalPages: 4,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<MergeLoading>());
    expect((states[1] as MergeError).message, 'corrupted document');

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = MergeCubit(_FakeMergeRepository(mergedBytes: mergedBytes));
    await cubit.merge(
      documents: [documentA, documentB],
      fileCount: 2,
      totalPages: 7,
    );
    expect(cubit.state, isA<MergeSuccess>());

    cubit.reset();

    expect(cubit.state, isA<MergeInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = MergeCubit(_FakeMergeRepository(mergedBytes: mergedBytes));
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });

  test('readPageCount returns the repository value without emitting', () async {
    final cubit = MergeCubit(_FakeMergeRepository(pageCount: 4));
    final states = <MergeState>[];
    final subscription = cubit.stream.listen(states.add);

    final count = await cubit.readPageCount(bytes: documentA);

    expect(count, 4);
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('readPageCount returns null instead of throwing on failure', () async {
    final cubit = MergeCubit(
      _FakeMergeRepository(
        error: const PdfEngineException('encrypted document'),
      ),
    );

    final count = await cubit.readPageCount(bytes: documentA);

    expect(count, isNull);
    expect(cubit.state, isA<MergeInitial>());

    await cubit.close();
  });
}
