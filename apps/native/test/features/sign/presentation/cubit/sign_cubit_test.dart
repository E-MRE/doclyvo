// Covers SignCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, reset() returning to Initial, and the
// non-emitting readPageCount passthrough — the same 4-state pattern every
// BaseCubit subclass follows. pageCount is passthrough display metadata handed
// in by the caller; signedPageNumber is the only value the cubit derives, and
// it is one-based.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/features/sign/data/repositories/sign_repository.dart';
import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';
import 'package:doclyvo/features/sign/presentation/cubit/sign_cubit.dart';
import 'package:doclyvo/features/sign/presentation/cubit/sign_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeSignRepository implements SignRepository {
  _FakeSignRepository({this.signedBytes, this.error, this.pageCount});

  final Uint8List? signedBytes;
  final Exception? error;
  final int? pageCount;

  Uint8List? lastImageBytes;
  int? lastPageIndex;
  SignaturePlacement? lastPlacement;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final error = this.error;
    if (error != null) throw error;
    return pageCount!;
  }

  @override
  Future<Uint8List> sign({
    required Uint8List bytes,
    required Uint8List signatureImageBytes,
    required int pageIndex,
    required SignaturePlacement placement,
  }) async {
    lastImageBytes = signatureImageBytes;
    lastPageIndex = pageIndex;
    lastPlacement = placement;
    final error = this.error;
    if (error != null) throw error;
    return signedBytes!;
  }
}

void main() {
  final inputBytes = Uint8List.fromList(List.filled(10, 1));
  final imageBytes = Uint8List.fromList(List.filled(6, 3));
  final resultBytes = Uint8List.fromList(List.filled(4, 2));
  const placement = SignaturePlacement.bottomRight;

  test('starts in SignInitial', () {
    final cubit = SignCubit(_FakeSignRepository());
    expect(cubit.state, isA<SignInitial>());
    unawaited(cubit.close());
  });

  test('emits Loading then Success with the signed bytes and page data', () async {
    final cubit = SignCubit(_FakeSignRepository(signedBytes: resultBytes));
    final states = <SignState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.sign(
      bytes: inputBytes,
      signatureImageBytes: imageBytes,
      pageIndex: 2,
      placement: placement,
      pageCount: 9,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<SignLoading>());
    final success = states[1] as SignSuccess;
    expect(success.signedBytes, same(resultBytes));
    expect(success.pageCount, 9);
    // Zero-based index in, one-based page number out.
    expect(success.signedPageNumber, 3);

    await subscription.cancel();
    await cubit.close();
  });

  test('signedPageNumber is 1 for the first page', () async {
    final cubit = SignCubit(_FakeSignRepository(signedBytes: resultBytes));

    await cubit.sign(
      bytes: inputBytes,
      signatureImageBytes: imageBytes,
      pageIndex: 0,
      placement: placement,
      pageCount: 1,
    );

    expect((cubit.state as SignSuccess).signedPageNumber, 1);

    await cubit.close();
  });

  test('emits Loading then Error when the repository throws', () async {
    final cubit = SignCubit(
      _FakeSignRepository(
        error: const PdfEngineException('Signature page is outside the document.'),
      ),
    );
    final states = <SignState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.sign(
      bytes: inputBytes,
      signatureImageBytes: imageBytes,
      pageIndex: 4,
      placement: placement,
      pageCount: 2,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<SignLoading>());
    expect(
      (states[1] as SignError).message,
      'Signature page is outside the document.',
    );

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = SignCubit(_FakeSignRepository(signedBytes: resultBytes));
    await cubit.sign(
      bytes: inputBytes,
      signatureImageBytes: imageBytes,
      pageIndex: 0,
      placement: placement,
      pageCount: 1,
    );
    expect(cubit.state, isA<SignSuccess>());

    cubit.reset();

    expect(cubit.state, isA<SignInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = SignCubit(_FakeSignRepository(signedBytes: resultBytes));
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });

  test('readPageCount returns the repository value without emitting', () async {
    final cubit = SignCubit(_FakeSignRepository(pageCount: 24));
    final states = <SignState>[];
    final subscription = cubit.stream.listen(states.add);

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, 24);
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('readPageCount returns null instead of throwing on failure', () async {
    final cubit = SignCubit(
      _FakeSignRepository(error: const PdfEngineException('corrupted document')),
    );

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, isNull);
    expect(cubit.state, isA<SignInitial>());

    await cubit.close();
  });

  test('sign forwards the image bytes, page index and placement instance', () async {
    final repository = _FakeSignRepository(signedBytes: resultBytes);
    final cubit = SignCubit(repository);

    await cubit.sign(
      bytes: inputBytes,
      signatureImageBytes: imageBytes,
      pageIndex: 5,
      placement: placement,
      pageCount: 8,
    );

    expect(repository.lastImageBytes, same(imageBytes));
    expect(repository.lastPageIndex, 5);
    expect(repository.lastPlacement, same(placement));

    await cubit.close();
  });
}
