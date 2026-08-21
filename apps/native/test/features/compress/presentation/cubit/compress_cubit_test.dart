// Covers CompressCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, and reset() returning to Initial — the 4-state
// pattern every BaseCubit subclass follows.
//
// No bloc_test dependency exists in this project (see pubspec.yaml), so the
// transitions are asserted directly against the emitted stream.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/features/compress/data/repositories/compress_repository.dart';
import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_cubit.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeCompressRepository implements CompressRepository {
  _FakeCompressRepository({this.result, this.error});

  final Uint8List? result;
  final Exception? error;

  @override
  Future<Uint8List> compress({
    required Uint8List bytes,
    required CompressQuality quality,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return result!;
  }
}

void main() {
  final inputBytes = Uint8List.fromList(List.filled(10, 1));
  final outputBytes = Uint8List.fromList(List.filled(4, 2));

  test('starts in CompressInitial', () {
    final cubit = CompressCubit(_FakeCompressRepository());
    expect(cubit.state, isA<CompressInitial>());
    unawaited(cubit.close());
  });

  test('emits Loading then Success with correct before/after sizes', () async {
    final cubit = CompressCubit(_FakeCompressRepository(result: outputBytes));
    final states = <CompressState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.compress(
      bytes: inputBytes,
      quality: CompressQuality.recommended,
    );
    // `emit()` notifies stream listeners via a microtask, which may not have
    // run yet right after the awaited Future completes.
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<CompressLoading>());
    final success = states[1] as CompressSuccess;
    expect(success.originalSizeInBytes, 10);
    expect(success.compressedSizeInBytes, 4);
    expect(success.compressedBytes, same(outputBytes));

    await subscription.cancel();
    await cubit.close();
  });

  test('emits Loading then Error when the repository throws', () async {
    final cubit = CompressCubit(
      _FakeCompressRepository(
        error: const PdfEngineException('corrupted document'),
      ),
    );
    final states = <CompressState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.compress(bytes: inputBytes, quality: CompressQuality.low);
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<CompressLoading>());
    expect((states[1] as CompressError).message, 'corrupted document');

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = CompressCubit(_FakeCompressRepository(result: outputBytes));
    await cubit.compress(
      bytes: inputBytes,
      quality: CompressQuality.recommended,
    );
    expect(cubit.state, isA<CompressSuccess>());

    cubit.reset();

    expect(cubit.state, isA<CompressInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = CompressCubit(_FakeCompressRepository(result: outputBytes));
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });
}
