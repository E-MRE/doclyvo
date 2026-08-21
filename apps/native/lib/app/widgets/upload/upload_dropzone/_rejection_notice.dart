part of '../upload_dropzone.dart';

/// Inline validation message shown when a selection is refused.
final class _RejectionNotice extends StatelessWidget {
  const _RejectionNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppInsets.onlyTop8,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: Sizes.lg,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: Sizes.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
