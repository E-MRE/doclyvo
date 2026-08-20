import 'package:doclyvo/core/config/environment_profile.dart';
import 'package:doclyvo/core/dependency/dependency_injection_service.dart';
import 'package:doclyvo/core/dependency/dependency_injector.dart';
import 'package:doclyvo/core/dependency/get_it_dependency_injection_manager.dart';

final class AppDependency {
  static DependencyInjectionService get dependency =>
      GetItDependencyInjectionManager();

  static DependencyInjector get injector =>
      GetItDependencyInjectionManager().injector;

  static T getEnvironment<T extends EnvironmentProfile>() =>
      injector.get<T>();
}
