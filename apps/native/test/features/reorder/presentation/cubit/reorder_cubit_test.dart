// Covers ReorderCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, reset() returning to Initial, and the
// non-emitting readPageCount() passthrough — the 4-state pattern every
// BaseCubit subclass follows, plus the renderThumbnails stream passthrough
// Reorder needs for its per-page preview grid.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/features/reorder/data/repositories/reorder_repository.dart';
import 'package:doclyvo/features/reorder/presentation/cubit/reorder_cubit.dart';
import 'package:doclyvo/features/reorder/presentation/cubit/reorder_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeReorderRepository implements ReorderRepository {
  _FakeReorderRepository({
    this.reorderedBytes,
    this.error,
    this.pageCount,
    this.thumbnails,
  });

  final Uint8List? reorderedBytes;
  final Exception? error;
  final int? pageCount;
  final Stream<PdfPageThumbnail>? thumbnails;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final error = this.error;
    if (error != null) throw error;
    return pageCount!;
  }

  @override
  Stream<PdfPageThumbnail> renderThumbnails({required Uint8List bytes}) {
    return thumbnails!;
  }

  @override
  Future<Uint8List> reorderPages({
    required Uint8List bytes,
    required List<int> pageOrder,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return reorderedBytes!;
  }
}

void main() {
  final inputBytes = Uint8List.fromList(List.filled(10, 1));
  final reorderedBytes = Uint8List.fromList(List.filled(4, 2));
  final pageOrder = [2, 0, 1];

  test('starts in ReorderInitial', () {
    final cubit = ReorderCubit(_FakeReorderRepository());
    expect(cubit.state, isA<ReorderInitial>());
    unawaited(cubit.close());
  });

  test('emits Loading then Success with the reordered bytes and page count', () async {
    final cubit = ReorderCubit(
      _FakeReorderRepository(reorderedBytes: reorderedBytes),
    );
    final states = <ReorderState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.reorder(
      bytes: inputBytes,
      pageOrder: pageOrder,
      pageCount: 3,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<ReorderLoading>());
    final success = states[1] as ReorderSuccess;
    expect(success.pageCount, 3);
    expect(success.reorderedBytes, same(reorderedBytes));

    await subscription.cancel();
    await cubit.close();
  });

  test('emits Loading then Error when the repository throws', () async {
    final cubit = ReorderCubit(
      _FakeReorderRepository(
        error: const PdfEngineException('corrupted document'),
      ),
    );
    final states = <ReorderState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.reorder(
      bytes: inputBytes,
      pageOrder: pageOrder,
      pageCount: 3,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<ReorderLoading>());
    expect((states[1] as ReorderError).message, 'corrupted document');

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = ReorderCubit(
      _FakeReorderRepository(reorderedBytes: reorderedBytes),
    );
    await cubit.reorder(
      bytes: inputBytes,
      pageOrder: pageOrder,
      pageCount: 3,
    );
    expect(cubit.state, isA<ReorderSuccess>());

    cubit.reset();

    expect(cubit.state, isA<ReorderInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = ReorderCubit(
      _FakeReorderRepository(reorderedBytes: reorderedBytes),
    );
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });

  test('readPageCount returns the repository value without emitting', () async {
    final cubit = ReorderCubit(_FakeReorderRepository(pageCount: 18));
    final states = <ReorderState>[];
    final subscription = cubit.stream.listen(states.add);

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, 18);
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('readPageCount returns null instead of throwing on failure', () async {
    final cubit = ReorderCubit(
      _FakeReorderRepository(
        error: const PdfEngineException('encrypted document'),
      ),
    );

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, isNull);
    expect(cubit.state, isA<ReorderInitial>());

    await cubit.close();
  });

  test('renderThumbnails forwards the repository stream events unchanged', () async {
    final thumbnails = [
      PdfPageThumbnail(
        pageIndex: 0,
        width: 100,
        height: 200,
        pngBytes: Uint8List.fromList([1, 2, 3]),
      ),
      PdfPageThumbnail(
        pageIndex: 1,
        width: 100,
        height: 200,
        pngBytes: Uint8List.fromList([4, 5, 6]),
      ),
    ];
    final cubit = ReorderCubit(
      _FakeReorderRepository(thumbnails: Stream.fromIterable(thumbnails)),
    );

    final result = await cubit.renderThumbnails(bytes: inputBytes).toList();

    expect(result, thumbnails);

    await cubit.close();
  });
}
