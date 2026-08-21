import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/merge/data/repositories/merge_repository.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Merge DI Registration', () {
    setUp(() {
      final registrar = _TestDependencyRegistrar();
      registrar.registerDependencies(AppDependency.injector);
    });

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('MergeCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<MergeCubit>();
      expect(cubit, isA<MergeCubit>());
    });

    test('MergeCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<MergeCubit>();
      final cubit2 = AppDependency.injector.get<MergeCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('MergeRepository resolves through its abstract type', () {
      final repository = AppDependency.injector.get<MergeRepository>();
      expect(repository, isA<MergeRepository>());
    });
  });
}
