import 'package:flutter/widgets.dart';

final class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.route,
    required this.icon,
    this.featured = false,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final String route;
  final IconData icon;
  final bool featured;
}
