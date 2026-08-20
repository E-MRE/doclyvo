import 'package:doclyvo/core/localization/localization_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

final class LocalizationWrapper extends StatelessWidget {
  const LocalizationWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: LocalizationConfig.supportedLocales,
      fallbackLocale: LocalizationConfig.fallbackLocale,
      path: LocalizationConfig.path,
      child: child,
    );
  }
}
