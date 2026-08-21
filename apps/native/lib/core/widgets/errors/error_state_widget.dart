import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

final class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.message,
    required this.onRetry,
    this.tier = ScreenTier.desktop,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final ScreenTier tier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = tier == ScreenTier.mobile;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? Sizes.lg : Sizes.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: isMobile ? 64 : 80,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: isMobile ? Sizes.md : Sizes.lg),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 400,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              SizedBox(height: isMobile ? Sizes.lg : Sizes.xl),
              _RetryButton(onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RetryButton extends StatefulWidget {
  const _RetryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isPressed = false),
      onExit: (_) => setState(() => _isPressed = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.xl,
            vertical: Sizes.md,
          ),
          decoration: BoxDecoration(
            color: _isPressed
                ? theme.colorScheme.error.withAlpha(200)
                : theme.colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Tekrar Dene',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onError,
            ),
          ),
        ),
      ),
    );
  }
}
