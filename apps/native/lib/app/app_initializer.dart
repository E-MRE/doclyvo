import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

final class AppInitializer with AppDependencyRegisterMixin {
  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    registerDependencies(AppDependency.injector);
  }
}
