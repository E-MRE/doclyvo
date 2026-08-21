import 'package:doclyvo/core/error/pdf_engine_exception.dart';
import 'package:doclyvo/core/error/response_exception.dart';
import 'package:doclyvo/core/states/base_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

abstract class _TestState {
  const _TestState();
}

final class _TestInitial implements _TestState {
  const _TestInitial();
}

final class _TestLoading implements _TestState {
  const _TestLoading();
}

final class _TestSuccess implements _TestState {
  const _TestSuccess({required this.value});
  final int value;
}

final class _TestError implements _TestState {
  const _TestError({this.message = ''});
  final String message;
}

final class _TestCubit extends BaseCubit<_TestState> {
  _TestCubit() : super(const _TestInitial());

  Future<void> succeed() {
    return safeCall<int>(
      action: () async => 42,
      loadingState: const _TestLoading(),
      successState: (data) => _TestSuccess(value: data),
      errorState: (message) => _TestError(message: message),
    );
  }

  Future<void> failWithNetworkError() {
    return safeCall<int>(
      action: () async => throw const ResponseException('network down'),
      loadingState: const _TestLoading(),
      successState: (data) => _TestSuccess(value: data),
      errorState: (message) => _TestError(message: message),
    );
  }

  Future<void> failWithPdfError() {
    return safeCall<int>(
      action: () async => throw const PdfEngineException(
        'bad pdf bytes',
        kind: PdfEngineErrorKind.corrupted,
      ),
      loadingState: const _TestLoading(),
      successState: (data) => _TestSuccess(value: data),
      errorState: (message) => _TestError(message: message),
    );
  }
}

void main() {
  test('safeEmit does not throw after close', () async {
    final cubit = _TestCubit();
    await cubit.close();

    expect(() => cubit.safeEmit(const _TestLoading()), returnsNormally);
  });

  test('safeCall does not throw or emit after close', () async {
    final cubit = _TestCubit();
    await cubit.close();

    await expectLater(cubit.succeed(), completes);
    expect(cubit.state, const _TestInitial());
  });

  test('safeCall resolves to a success state', () async {
    final cubit = _TestCubit();

    await cubit.succeed();

    expect(cubit.state, isA<_TestSuccess>());
    expect((cubit.state as _TestSuccess).value, 42);

    await cubit.close();
  });

  test('safeCall catches a network failure (ResponseException)', () async {
    final cubit = _TestCubit();

    await cubit.failWithNetworkError();

    expect(cubit.state, isA<_TestError>());
    expect((cubit.state as _TestError).message, 'network down');

    await cubit.close();
  });

  test('safeCall catches a client-side PDF engine failure', () async {
    final cubit = _TestCubit();

    await cubit.failWithPdfError();

    expect(cubit.state, isA<_TestError>());
    expect((cubit.state as _TestError).message, 'bad pdf bytes');

    await cubit.close();
  });
}
