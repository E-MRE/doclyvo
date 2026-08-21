part of '../home_header.dart';

/// Accent icon capsule plus the `doclyvo` word, the one element every tier
/// keeps.
final class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capsuleSize = isMobile ? Sizes.xl + Sizes.xs : Sizes.xxl + Sizes.xs;

    return Row(
      children: [
        Container(
          width: capsuleSize,
          height: capsuleSize,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(Sizes.radiusSmall),
          ),
          child: Icon(
            Icons.picture_as_pdf_outlined,
            size: Sizes.lg,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: Sizes.sm),
        Text(
          LocaleKeys.appName.tr(),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: isMobile ? Sizes.typeBody + 2 : Sizes.typeH2,
          ),
        ),
      ],
    );
  }
}
