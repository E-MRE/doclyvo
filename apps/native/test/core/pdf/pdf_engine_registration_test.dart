// Confirms P0-11's wiring: the client-side PDF engine resolves through
// AppDependency as its abstract type, so features never name the concrete
// implementation (or the engine package) themselves.

import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/core/pdf/pdf_manipulator_engine_service.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestRegistrar with AppDependencyRegisterMixin {}

void main() {
  tearDown(() async {
    await AppDependency.injector.reset();
  });

  test('PdfEngineService is registered as a shared instance', () {
    _TestRegistrar().registerDependencies(AppDependency.injector);

    final engine = AppDependency.injector.get<PdfEngineService>();

    expect(engine, isA<PdfManipulatorEngineService>());
    expect(
      AppDependency.injector.get<PdfEngineService>(),
      same(engine),
      reason: 'the engine holds a native binary — it must be a singleton',
    );
  });
}
