import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/reorder/data/repositories/reorder_repository.dart';
import 'package:doclyvo/features/reorder/presentation/cubit/reorder_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Reorder DI Registration', () {
    setUp(() {
      final registrar = _TestDependencyRegistrar();
      registrar.registerDependencies(AppDependency.injector);
    });

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('ReorderCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<ReorderCubit>();
      expect(cubit, isA<ReorderCubit>());
    });

    test('ReorderCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<ReorderCubit>();
      final cubit2 = AppDependency.injector.get<ReorderCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('ReorderRepository resolves through its abstract type', () {
      final repository = AppDependency.injector.get<ReorderRepository>();
      expect(repository, isA<ReorderRepository>());
    });
  });
}
