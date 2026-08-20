import 'package:doclyvo/core/config/configurations.dart';
import 'package:doclyvo/core/dependency/dependency_injector.dart';

mixin AppDependencyRegisterMixin {
  void registerDependencies(DependencyInjector injector) {
    _registerCoreDependencies(injector);
    _registerNetworkDependencies(injector);
    if (Configurations.isDevelopment) {
      _registerDevelopmentDependencies(injector);
    } else {
      _registerReleaseDependencies(injector);
    }
    _registerRepositories(injector);
    _registerCubits(injector);
  }

  void _registerCoreDependencies(DependencyInjector injector) {}

  void _registerNetworkDependencies(DependencyInjector injector) {}

  void _registerDevelopmentDependencies(DependencyInjector injector) {}

  void _registerReleaseDependencies(DependencyInjector injector) {}

  void _registerRepositories(DependencyInjector injector) {}

  void _registerCubits(DependencyInjector injector) {}
}
