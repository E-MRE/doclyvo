import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/rotate/data/repositories/rotate_repository.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Rotate DI Registration', () {
    setUp(
      () => _TestDependencyRegistrar().registerDependencies(
        AppDependency.injector,
      ),
    );

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('RotateCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<RotateCubit>();
      expect(cubit, isA<RotateCubit>());
    });

    test('RotateCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<RotateCubit>();
      final cubit2 = AppDependency.injector.get<RotateCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('RotateRepository resolves through its abstract type', () {
      final repository = AppDependency.injector.get<RotateRepository>();
      expect(repository, isA<RotateRepository>());
    });
  });
}
