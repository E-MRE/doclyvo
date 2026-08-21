import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

final class BaseErrorContainer extends StatelessWidget {
  const BaseErrorContainer({
    required this.message,
    required this.buttonText,
    required this.onPressed,
    super.key,
  });

  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: Sizes.typeDisplay,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: Sizes.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Sizes.lg),
            PrimaryButton(label: buttonText, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}
