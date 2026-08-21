// Covers WatermarkCubit's state transitions: Initial -> Loading -> Success,
// Initial -> Loading -> Error, reset() returning to Initial, and the two
// non-emitting passthroughs (readPageCount, renderFirstPageThumbnail) — the
// 4-state pattern every BaseCubit subclass follows, plus the two extra
// passthroughs Watermark needs for its idle-state page-count summary and
// live settings preview.

import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/features/watermark/data/repositories/watermark_repository.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_cubit.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_state.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeWatermarkRepository implements WatermarkRepository {
  _FakeWatermarkRepository({
    this.watermarkedBytes,
    this.error,
    this.pageCount,
    this.thumbnail,
  });

  final Uint8List? watermarkedBytes;
  final Exception? error;
  final int? pageCount;
  final PdfPageThumbnail? thumbnail;

  @override
  Future<int> readPageCount({required Uint8List bytes}) async {
    final error = this.error;
    if (error != null) throw error;
    return pageCount!;
  }

  @override
  Future<PdfPageThumbnail?> renderFirstPageThumbnail({
    required Uint8List bytes,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return thumbnail;
  }

  @override
  Future<Uint8List> addWatermark({
    required Uint8List bytes,
    required PdfWatermarkOptions options,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    return watermarkedBytes!;
  }
}

void main() {
  final inputBytes = Uint8List.fromList(List.filled(10, 1));
  final resultBytes = Uint8List.fromList(List.filled(4, 2));
  const options = PdfWatermarkOptions(text: 'Doclyvo');

  test('starts in WatermarkInitial', () {
    final cubit = WatermarkCubit(_FakeWatermarkRepository());
    expect(cubit.state, isA<WatermarkInitial>());
    unawaited(cubit.close());
  });

  test('emits Loading then Success with the watermarked bytes and page count', () async {
    final cubit = WatermarkCubit(
      _FakeWatermarkRepository(watermarkedBytes: resultBytes),
    );
    final states = <WatermarkState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.addWatermark(
      bytes: inputBytes,
      options: options,
      pageCount: 4,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<WatermarkLoading>());
    final success = states[1] as WatermarkSuccess;
    expect(success.pageCount, 4);
    expect(success.watermarkedBytes, same(resultBytes));

    await subscription.cancel();
    await cubit.close();
  });

  test('emits Loading then Error when the repository throws', () async {
    final cubit = WatermarkCubit(
      _FakeWatermarkRepository(
        error: const PdfEngineException('corrupted document'),
      ),
    );
    final states = <WatermarkState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.addWatermark(
      bytes: inputBytes,
      options: options,
      pageCount: 4,
    );
    await Future<void>.delayed(Duration.zero);

    expect(states, hasLength(2));
    expect(states[0], isA<WatermarkLoading>());
    expect((states[1] as WatermarkError).message, 'corrupted document');

    await subscription.cancel();
    await cubit.close();
  });

  test('reset() returns to Initial after a Success', () async {
    final cubit = WatermarkCubit(
      _FakeWatermarkRepository(watermarkedBytes: resultBytes),
    );
    await cubit.addWatermark(
      bytes: inputBytes,
      options: options,
      pageCount: 4,
    );
    expect(cubit.state, isA<WatermarkSuccess>());

    cubit.reset();

    expect(cubit.state, isA<WatermarkInitial>());
    await cubit.close();
  });

  test('does not throw when safeEmit runs after close()', () async {
    final cubit = WatermarkCubit(
      _FakeWatermarkRepository(watermarkedBytes: resultBytes),
    );
    await cubit.close();

    expect(cubit.reset, returnsNormally);
  });

  test('readPageCount returns the repository value without emitting', () async {
    final cubit = WatermarkCubit(_FakeWatermarkRepository(pageCount: 18));
    final states = <WatermarkState>[];
    final subscription = cubit.stream.listen(states.add);

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, 18);
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('readPageCount returns null instead of throwing on failure', () async {
    final cubit = WatermarkCubit(
      _FakeWatermarkRepository(
        error: const PdfEngineException('encrypted document'),
      ),
    );

    final count = await cubit.readPageCount(bytes: inputBytes);

    expect(count, isNull);
    expect(cubit.state, isA<WatermarkInitial>());

    await cubit.close();
  });

  test('renderFirstPageThumbnail returns the repository value without emitting', () async {
    final thumbnail = PdfPageThumbnail(
      pageIndex: 0,
      width: 100,
      height: 200,
      pngBytes: Uint8List.fromList([1, 2, 3]),
    );
    final cubit = WatermarkCubit(
      _FakeWatermarkRepository(thumbnail: thumbnail),
    );
    final states = <WatermarkState>[];
    final subscription = cubit.stream.listen(states.add);

    final result = await cubit.renderFirstPageThumbnail(bytes: inputBytes);

    expect(result, same(thumbnail));
    expect(states, isEmpty);

    await subscription.cancel();
    await cubit.close();
  });

  test('renderFirstPageThumbnail returns null instead of throwing on failure', () async {
    final cubit = WatermarkCubit(
      _FakeWatermarkRepository(
        error: const PdfEngineException('encrypted document'),
      ),
    );

    final result = await cubit.renderFirstPageThumbnail(bytes: inputBytes);

    expect(result, isNull);
    expect(cubit.state, isA<WatermarkInitial>());

    await cubit.close();
  });
}
