import 'package:doclyvo/core/dependency/dependency_injection_service.dart';
import 'package:doclyvo/core/dependency/get_it_dependency_injector.dart';

final class GetItDependencyInjectionManager extends DependencyInjectionService {
  factory GetItDependencyInjectionManager() => _instance;

  GetItDependencyInjectionManager._internal()
      : super(injector: GetItDependencyInjector());

  static final GetItDependencyInjectionManager _instance =
      GetItDependencyInjectionManager._internal();
}
