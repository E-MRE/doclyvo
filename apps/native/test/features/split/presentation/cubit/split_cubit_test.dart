// Covers SplitCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, reset() returning to Initial, and the
// non-emitting readPageCount() passthrough — the 4-state pattern every
// BaseCubit subclass follows, plus the one extra passthrough Split needs
// for its idle-state page-count summary.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/features/split/data/repositories/split_repository.dart';
import 'package:doclyvo/features/split/domain/models/split_result.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_cubit.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeSplitRepository implements SplitRepository {
  _FakeSplitRepository({this.result, this.error, this.pageCount});

  final SplitResult? result;
  final Exception? error;
  final int? pageCount;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final error = this.error;
    if (error != null) throw error;
    return pageCount!;
  }

  @override
  Future<SplitResult> split({required Uint8List bytes}) async {
    final error = this.error;
    if (error != null) throw error;
    return result!;
  }
}

void main() {
  final inputBytes = Uint8List.fromList(List.filled(10, 1));
  final zipBytes = Uint8List.fromList(List.filled(4, 2));

  test('starts in SplitInitial', () {
    final cubit = SplitCubit(_FakeSplitRepository());
    expect(cubit.state, isA<SplitInitial>());
    unawaited(cubit.close());
  });

  test('emits Loading then Success with the zip bytes and page count', () async {
    final cubit = SplitCubit(
      _FakeSplitRepository(
        result: SplitResult(zipBytes: zipBytes, pageCount: 4),
      ),
    );
    final states = <SplitState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.split(bytes: inputBytes);
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<SplitLoading>());
    final success = states[1] as SplitSuccess;
    expect(success.pageCount, 4);
    expect(success.zipBytes, same(zipBytes));

    await subscription.cancel();
    await cubit.close();
  });

  test('emits Loading then Error when the repository throws', () async {
    final cubit = SplitCubit(
      _FakeSplitRepository(
        error: const PdfEngineException('corrupted document'),
      ),
    );
    final states = <SplitState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.split(bytes: inputBytes);
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<SplitLoading>());
    expect((states[1] as SplitError).message, 'corrupted document');

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = SplitCubit(
      _FakeSplitRepository(
        result: SplitResult(zipBytes: zipBytes, pageCount: 4),
      ),
    );
    await cubit.split(bytes: inputBytes);
    expect(cubit.state, isA<SplitSuccess>());

    cubit.reset();

    expect(cubit.state, isA<SplitInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = SplitCubit(
      _FakeSplitRepository(
        result: SplitResult(zipBytes: zipBytes, pageCount: 4),
      ),
    );
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });

  test('readPageCount returns the repository value without emitting', () async {
    final cubit = SplitCubit(_FakeSplitRepository(pageCount: 18));
    final states = <SplitState>[];
    final subscription = cubit.stream.listen(states.add);

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, 18);
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('readPageCount returns null instead of throwing on failure', () async {
    final cubit = SplitCubit(
      _FakeSplitRepository(
        error: const PdfEngineException('encrypted document'),
      ),
    );

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, isNull);
    expect(cubit.state, isA<SplitInitial>());

    await cubit.close();
  });
}
