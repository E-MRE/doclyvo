import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/watermark/data/repositories/watermark_repository.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Watermark DI Registration', () {
    setUp(
      () => _TestDependencyRegistrar().registerDependencies(
        AppDependency.injector,
      ),
    );

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('WatermarkCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<WatermarkCubit>();
      expect(cubit, isA<WatermarkCubit>());
    });

    test('WatermarkCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<WatermarkCubit>();
      final cubit2 = AppDependency.injector.get<WatermarkCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('WatermarkRepository resolves through its abstract type', () {
      final repository = AppDependency.injector.get<WatermarkRepository>();
      expect(repository, isA<WatermarkRepository>());
    });
  });
}
