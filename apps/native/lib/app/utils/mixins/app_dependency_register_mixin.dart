import 'package:dio/dio.dart';
import 'package:doclyvo/core/config/configurations.dart';
import 'package:doclyvo/core/dependency/dependency_injector.dart';
import 'package:doclyvo/core/network/dio_network_manager.dart';
import 'package:doclyvo/core/network/network_service.dart';

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

  void _registerNetworkDependencies(DependencyInjector injector) {
    injector.registerFactory<Dio>(
      () => Dio(
        BaseOptions(
          baseUrl: Configurations.environmentProfile.baseUrl,
          connectTimeout: const Duration(seconds: 32),
          receiveTimeout: const Duration(seconds: 32),
          sendTimeout: const Duration(seconds: 32),
        ),
      ),
    );

    injector.registerSingleton<NetworkService>(
      DioNetworkManager(injector.get<Dio>()),
    );
  }

  void _registerDevelopmentDependencies(DependencyInjector injector) {}

  void _registerReleaseDependencies(DependencyInjector injector) {}

  void _registerRepositories(DependencyInjector injector) {}

  void _registerCubits(DependencyInjector injector) {}
}
