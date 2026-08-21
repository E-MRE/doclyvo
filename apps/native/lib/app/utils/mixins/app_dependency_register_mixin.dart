import 'package:dio/dio.dart';
import 'package:doclyvo/app/theme/theme_manager.dart';
import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:doclyvo/core/config/configurations.dart';
import 'package:doclyvo/core/dependency/dependency_injector.dart';
import 'package:doclyvo/core/network/dio_network_manager.dart';
import 'package:doclyvo/core/network/network_service.dart';
import 'package:doclyvo/core/pdf/pdf_engine_service.dart';
import 'package:doclyvo/core/pdf/pdf_manipulator_engine_service.dart';
import 'package:doclyvo/features/home/presentation/cubit/home_cubit.dart';

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

  void _registerCoreDependencies(DependencyInjector injector) {
    // The engine owns a worker and a loaded native binary — one shared
    // instance for the whole app, created on first use by whichever tool
    // needs it first.
    injector
      ..registerLazySingleton<PdfEngineService>(
        PdfManipulatorEngineService.new,
        dispose: (service) => service.dispose(),
      )
      ..registerLazySingleton<ThemeService>(ThemeManager.new);
  }

  void _registerNetworkDependencies(DependencyInjector injector) {
    injector
      ..registerFactory<Dio>(
        () => Dio(
          BaseOptions(
            baseUrl: Configurations.environmentProfile.baseUrl,
            connectTimeout: const Duration(seconds: 32),
            receiveTimeout: const Duration(seconds: 32),
            sendTimeout: const Duration(seconds: 32),
          ),
        ),
      )
      ..registerSingleton<NetworkService>(
        DioNetworkManager(injector.get<Dio>()),
      );
  }

  void _registerDevelopmentDependencies(DependencyInjector injector) {}

  void _registerReleaseDependencies(DependencyInjector injector) {}

  void _registerRepositories(DependencyInjector injector) {}

  void _registerCubits(DependencyInjector injector) {
    injector.registerFactory<HomeCubit>(HomeCubit.new);
  }
}
