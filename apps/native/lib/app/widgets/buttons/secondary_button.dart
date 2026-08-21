import 'package:doclyvo/app/widgets/buttons/press_scale.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

final class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.disabledOpacity = 0.55,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double disabledOpacity;

  bool get _isEnabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressScale(
      enabled: _isEnabled,
      onTap: onPressed,
      child: Opacity(
        opacity: _isEnabled ? 1 : disabledOpacity,
        child: Container(
          padding: AppInsets.symmetricH24.add(AppInsets.symmetricV12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(Sizes.radiusButton),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: Sizes.lg, color: theme.colorScheme.onSurface),
                const SizedBox(width: Sizes.sm),
              ],
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
