// Covers RotateCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, reset() returning to Initial, and the two
// non-emitting passthroughs — readPageCount() and renderThumbnails() — the
// 4-state pattern every BaseCubit subclass follows, plus the extra
// passthroughs Rotate needs for its idle-state page grid.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/features/rotate/data/repositories/rotate_repository.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_cubit.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeRotateRepository implements RotateRepository {
  _FakeRotateRepository({
    this.rotatedBytes,
    this.error,
    this.pageCount,
    this.thumbnails,
  });

  final Uint8List? rotatedBytes;
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
  Future<Uint8List> rotatePages({
    required Uint8List bytes,
    required Map<int, int> pageRotations,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return rotatedBytes!;
  }
}

void main() {
  final inputBytes = Uint8List.fromList(List.filled(10, 1));
  final rotatedBytes = Uint8List.fromList(List.filled(4, 2));

  test('starts in RotateInitial', () {
    final cubit = RotateCubit(_FakeRotateRepository());
    expect(cubit.state, isA<RotateInitial>());
    unawaited(cubit.close());
  });

  test(
    'emits Loading then Success with the rotated bytes and page counts',
    () async {
      final cubit = RotateCubit(
        _FakeRotateRepository(rotatedBytes: rotatedBytes),
      );
      final states = <RotateState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.rotate(
        bytes: inputBytes,
        pageRotations: {0: 90},
        pageCount: 4,
        rotatedPageCount: 1,
      );
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(2));
      expect(states[0], isA<RotateLoading>());
      final success = states[1] as RotateSuccess;
      expect(success.rotatedBytes, same(rotatedBytes));
      expect(success.pageCount, 4);
      expect(success.rotatedPageCount, 1);

      await subscription.cancel();
      await cubit.close();
    },
  );

  test('emits Loading then Error when the repository throws', () async {
    final cubit = RotateCubit(
      _FakeRotateRepository(
        error: const PdfEngineException('corrupted document'),
      ),
    );
    final states = <RotateState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.rotate(
      bytes: inputBytes,
      pageRotations: {0: 90},
      pageCount: 4,
      rotatedPageCount: 1,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<RotateLoading>());
    expect((states[1] as RotateError).message, 'corrupted document');

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = RotateCubit(
      _FakeRotateRepository(rotatedBytes: rotatedBytes),
    );
    await cubit.rotate(
      bytes: inputBytes,
      pageRotations: {0: 90},
      pageCount: 4,
      rotatedPageCount: 1,
    );
    expect(cubit.state, isA<RotateSuccess>());

    cubit.reset();

    expect(cubit.state, isA<RotateInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = RotateCubit(
      _FakeRotateRepository(rotatedBytes: rotatedBytes),
    );
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });

  test('readPageCount returns the repository value without emitting', () async {
    final cubit = RotateCubit(_FakeRotateRepository(pageCount: 18));
    final states = <RotateState>[];
    final subscription = cubit.stream.listen(states.add);

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, 18);
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('readPageCount returns null instead of throwing on failure', () async {
    final cubit = RotateCubit(
      _FakeRotateRepository(
        error: const PdfEngineException('encrypted document'),
      ),
    );

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, isNull);
    expect(cubit.state, isA<RotateInitial>());

    await cubit.close();
  });

  test('renderThumbnails forwards the repository stream unchanged', () async {
    final first = PdfPageThumbnail(
      pageIndex: 0,
      width: 100,
      height: 200,
      pngBytes: Uint8List.fromList([1, 2, 3]),
    );
    final second = PdfPageThumbnail(
      pageIndex: 1,
      width: 100,
      height: 200,
      pngBytes: Uint8List.fromList([4, 5, 6]),
    );
    final cubit = RotateCubit(
      _FakeRotateRepository(
        thumbnails: Stream.fromIterable([first, second]),
      ),
    );

    final events = await cubit.renderThumbnails(bytes: inputBytes).toList();

    expect(events, [same(first), same(second)]);

    await cubit.close();
  });
}
