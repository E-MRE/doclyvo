import 'package:doclyvo/app/app_dependency.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestService {
  const _TestService(this.value);

  final int value;
}

void main() {
  tearDown(() async {
    await AppDependency.injector.reset();
  });

  test('resolves a trivially registered dependency via AppDependency', () {
    AppDependency.injector.registerFactory<_TestService>(
      () => const _TestService(42),
    );

    final resolved = AppDependency.injector.get<_TestService>();

    expect(resolved.value, 42);
  });
}
