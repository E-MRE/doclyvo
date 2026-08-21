import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:flutter/material.dart';

final class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = AppInsets.all16,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
