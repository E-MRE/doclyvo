import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/home/presentation/cubit/home_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Home DI Registration', () {
    setUp(() {
      final registrar = _TestDependencyRegistrar();
      registrar.registerDependencies(AppDependency.injector);
    });

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('HomeCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<HomeCubit>();
      expect(cubit, isA<HomeCubit>());
    });

    test('HomeCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<HomeCubit>();
      final cubit2 = AppDependency.injector.get<HomeCubit>();
      expect(cubit1, isNot(cubit2));
    });
  });
}
