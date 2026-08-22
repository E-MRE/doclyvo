import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/features/sign/data/repositories/pdf_engine_sign_repository.dart';
import 'package:doclyvo/features/sign/data/repositories/sign_repository.dart';
import 'package:doclyvo/features/sign/presentation/cubit/sign_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestDependencyRegistrar with AppDependencyRegisterMixin {}

void main() {
  group('Sign DI Registration', () {
    setUp(
      () => _TestDependencyRegistrar().registerDependencies(
        AppDependency.injector,
      ),
    );

    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('SignCubit is registered and can be obtained via DI', () {
      final cubit = AppDependency.injector.get<SignCubit>();
      expect(cubit, isA<SignCubit>());
    });

    test('SignCubit factory returns new instances', () {
      final cubit1 = AppDependency.injector.get<SignCubit>();
      final cubit2 = AppDependency.injector.get<SignCubit>();
      expect(cubit1, isNot(cubit2));
    });

    test('SignRepository resolves to PdfEngineSignRepository', () {
      final repository = AppDependency.injector.get<SignRepository>();
      expect(repository, isA<PdfEngineSignRepository>());
    });
  });
}
