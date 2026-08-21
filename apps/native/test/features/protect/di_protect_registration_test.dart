import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/protect/data/repositories/protect_repository.dart';
import 'package:doclyvo/features/protect/presentation/cubit/protect_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Protect DI Registration', () {
    setUp(
      () => _TestDependencyRegistrar().registerDependencies(
        AppDependency.injector,
      ),
    );

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('ProtectCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<ProtectCubit>();
      expect(cubit, isA<ProtectCubit>());
    });

    test('ProtectCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<ProtectCubit>();
      final cubit2 = AppDependency.injector.get<ProtectCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('ProtectRepository resolves through its abstract type', () {
      final repository = AppDependency.injector.get<ProtectRepository>();
      expect(repository, isA<ProtectRepository>());
    });
  });
}
