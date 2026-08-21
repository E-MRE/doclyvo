import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/app_initializer.dart';
import 'package:doclyvo/app/app_router.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:doclyvo/app/widgets/wrappers/localization_wrapper.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await AppInitializer().initialize();
  runApp(const LocalizationWrapper(child: DoclyvoApp()));
}

final class DoclyvoApp extends StatelessWidget {
  const DoclyvoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = AppDependency.injector.get<ThemeService>();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp.router(
          title: LocaleKeys.appName.tr(),
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeService.themeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}
