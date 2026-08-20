import 'dart:async';

import 'package:get_it/get_it.dart';

abstract class DependencyInjector {
  T get<T extends Object>({
    String? instanceName,
    dynamic param1,
    dynamic param2,
    Type? type,
  });

  void registerFactory<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
  });

  T registerSingleton<T extends Object>(
    T instance, {
    String? instanceName,
    bool? signalsReady,
    DisposingFunc<T>? dispose,
  });

  void registerLazySingleton<T extends Object>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
    DisposingFunc<T>? dispose,
  });

  bool isRegistered<T extends Object>({
    Object? instance,
    String? instanceName,
  });

  Future<void> reset({bool dispose = true});

  FutureOr<dynamic> resetLazySingleton<T extends Object>({
    T? instance,
    String? instanceName,
    DisposingFunc<T>? disposingFunction,
  });

  FutureOr<dynamic> unregister<T extends Object>({
    Object? instance,
    String? instanceName,
    DisposingFunc<T>? disposingFunction,
  });
}
