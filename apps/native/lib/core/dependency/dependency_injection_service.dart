import 'package:doclyvo/core/dependency/dependency_injector.dart';

abstract class DependencyInjectionService {
  DependencyInjectionService({required this.injector});

  final DependencyInjector injector;
}
