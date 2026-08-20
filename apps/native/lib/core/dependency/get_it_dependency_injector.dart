import 'dart:async';

import 'package:doclyvo/core/dependency/dependency_injector.dart';
import 'package:get_it/get_it.dart';

final class GetItDependencyInjector implements DependencyInjector {
  final GetIt _getIt = GetIt.instance;

  @override
  T get<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
    Type? type,
  }) {
    return _getIt.get<T>(
      instanceName: instanceName,
      param1: param1,
      param2: param2,
      type: type,
    );
  }

  @override
  void registerFactory<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
  }) {
    _getIt.registerFactory<T>(factoryFunc, instanceName: instanceName);
  }

  @override
  T registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    bool? signalsReady,
    DisposingFunc<T>? dispose,
  }) {
    return _getIt.registerSingleton<T>(
      instance,
      instanceName: instanceName,
      signalsReady: signalsReady,
      dispose: dispose,
    );
  }

  @override
  void registerLazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    DisposingFunc<T>? dispose,
  }) {
    _getIt.registerLazySingleton<T>(
      factoryFunc,
      instanceName: instanceName,
      dispose: dispose,
    );
  }

  @override
  bool isRegistered<T extends Object>({
    Object? instance,
    String? instanceName,
  }) {
    return _getIt.isRegistered<T>(
      instance: instance,
      instanceName: instanceName,
    );
  }

  @override
  Future<void> reset({bool dispose = true}) {
    return _getIt.reset(dispose: dispose);
  }

  @override
  FutureOr<dynamic> resetLazySingleton<T extends Object>({
    T? instance,
    String? instanceName,
    DisposingFunc<T>? disposingFunction,
  }) {
    return _getIt.resetLazySingleton<T>(
      instance: instance,
      instanceName: instanceName,
      disposingFunction: disposingFunction,
    );
  }

  @override
  FutureOr<dynamic> unregister<T extends Object>({
    Object? instance,
    String? instanceName,
    DisposingFunc<T>? disposingFunction,
  }) {
    return _getIt.unregister<T>(
      instance: instance,
      instanceName: instanceName,
      disposingFunction: disposingFunction,
    );
  }
}
