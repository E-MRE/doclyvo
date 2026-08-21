import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/split/data/repositories/split_repository.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Split DI Registration', () {
    setUp(() {
      final registrar = _TestDependencyRegistrar();
      registrar.registerDependencies(AppDependency.injector);
    });

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('SplitCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<SplitCubit>();
      expect(cubit, isA<SplitCubit>());
    });

    test('SplitCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<SplitCubit>();
      final cubit2 = AppDependency.injector.get<SplitCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('SplitRepository resolves through its abstract type', () {
      final repository = AppDependency.injector.get<SplitRepository>();
      expect(repository, isA<SplitRepository>());
    });
  });
}
