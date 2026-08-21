// Covers ProtectCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, reset() returning to Initial, and the
// non-emitting readPageCount passthrough — the same 4-state pattern every
// BaseCubit subclass follows, plus the one extra passthrough Protect needs
// for its idle-state page-count summary. pageCount is passthrough display
// metadata handed in by the caller, never re-derived by the cubit.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/features/protect/data/repositories/protect_repository.dart';
import 'package:doclyvo/features/protect/presentation/cubit/protect_cubit.dart';
import 'package:doclyvo/features/protect/presentation/cubit/protect_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeProtectRepository implements ProtectRepository {
  _FakeProtectRepository({this.protectedBytes, this.error, this.pageCount});

  final Uint8List? protectedBytes;
  final Exception? error;
  final int? pageCount;

  PdfProtectionOptions? lastOptions;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final error = this.error;
    if (error != null) throw error;
    return pageCount!;
  }

  @override
  Future<Uint8List> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
  }) async {
    lastOptions = options;
    final error = this.error;
    if (error != null) throw error;
    return protectedBytes!;
  }
}

void main() {
  final inputBytes = Uint8List.fromList(List.filled(10, 1));
  final resultBytes = Uint8List.fromList(List.filled(4, 2));
  const options = PdfProtectionOptions(password: 'Doclyvo1!');

  test('starts in ProtectInitial', () {
    final cubit = ProtectCubit(_FakeProtectRepository());
    expect(cubit.state, isA<ProtectInitial>());
    unawaited(cubit.close());
  });

  test('emits Loading then Success with the protected bytes and page count', () async {
    final cubit = ProtectCubit(
      _FakeProtectRepository(protectedBytes: resultBytes),
    );
    final states = <ProtectState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.protect(bytes: inputBytes, options: options, pageCount: 4);
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<ProtectLoading>());
    final success = states[1] as ProtectSuccess;
    expect(success.pageCount, 4);
    expect(success.protectedBytes, same(resultBytes));

    await subscription.cancel();
    await cubit.close();
  });

  test('emits Loading then Error when the repository throws', () async {
    final cubit = ProtectCubit(
      _FakeProtectRepository(
        error: const PdfEngineException('corrupted document'),
      ),
    );
    final states = <ProtectState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.protect(bytes: inputBytes, options: options, pageCount: 4);
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<ProtectLoading>());
    expect((states[1] as ProtectError).message, 'corrupted document');

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = ProtectCubit(
      _FakeProtectRepository(protectedBytes: resultBytes),
    );
    await cubit.protect(bytes: inputBytes, options: options, pageCount: 4);
    expect(cubit.state, isA<ProtectSuccess>());

    cubit.reset();

    expect(cubit.state, isA<ProtectInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = ProtectCubit(
      _FakeProtectRepository(protectedBytes: resultBytes),
    );
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });

  test('readPageCount returns the repository value without emitting', () async {
    final cubit = ProtectCubit(_FakeProtectRepository(pageCount: 18));
    final states = <ProtectState>[];
    final subscription = cubit.stream.listen(states.add);

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, 18);
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('readPageCount returns null instead of throwing on failure', () async {
    final cubit = ProtectCubit(
      _FakeProtectRepository(
        error: const PdfEngineException('encrypted document'),
      ),
    );

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, isNull);
    expect(cubit.state, isA<ProtectInitial>());

    await cubit.close();
  });

  test('protect forwards the exact options instance to the repository', () async {
    final repository = _FakeProtectRepository(protectedBytes: resultBytes);
    final cubit = ProtectCubit(repository);

    await cubit.protect(bytes: inputBytes, options: options, pageCount: 4);

    expect(repository.lastOptions, same(options));

    await cubit.close();
  });
}
