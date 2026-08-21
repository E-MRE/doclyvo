import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/compress/data/repositories/compress_repository.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Compress DI Registration', () {
    setUp(() {
      final registrar = _TestDependencyRegistrar();
      registrar.registerDependencies(AppDependency.injector);
    });

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('CompressCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<CompressCubit>();
      expect(cubit, isA<CompressCubit>());
    });

    test('CompressCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<CompressCubit>();
      final cubit2 = AppDependency.injector.get<CompressCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('CompressRepository resolves through its abstract type', () {
      final repository = AppDependency.injector.get<CompressRepository>();
      expect(repository, isA<CompressRepository>());
    });
  });
}
