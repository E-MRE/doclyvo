import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/press_scale.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/home/domain/models/tool_definition.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

final class ToolCard extends StatelessWidget {
  const ToolCard({
    required this.tool,
    required this.onTap,
    this.horizontal = false,
    this.showDescription = true,
    super.key,
  });

  final ToolDefinition tool;
  final VoidCallback onTap;
  final bool horizontal;
  final bool showDescription;

  /// Tool names are short enough for one line at every cell size.
  static const int _titleMaxLines = 1;

  /// Two lines is what `design/Main.dc.html` draws under each tool name.
  static const int _descriptionMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featured = tool.featured;

    final iconBadge = Container(
      width: horizontal ? Sizes.xxl + Sizes.md : Sizes.xxl + Sizes.xs,
      height: horizontal ? Sizes.xxl + Sizes.md : Sizes.xxl + Sizes.xs,
      decoration: BoxDecoration(
        color: featured ? theme.colorScheme.primary : context.accentSoftColor,
        borderRadius: BorderRadius.circular(Sizes.radiusSmall + Sizes.xs),
      ),
      child: Icon(
        tool.icon,
        size: Sizes.xl - Sizes.xs,
        color: featured ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
      ),
    );

    // ToolGrid positions every card at a fixed cell height, so the text has
    // to be bounded: at compact desktop widths a column is only ~150px wide
    // and unclamped copy wraps past the cell instead of being clipped.
    final title = Text(
      tool.titleKey.tr(),
      maxLines: _titleMaxLines,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: featured ? FontWeight.w700 : FontWeight.w600,
        fontSize: featured && !horizontal ? Sizes.typeBody + 4 : null,
      ),
    );

    final description = showDescription
        ? Padding(
            padding: AppInsets.onlyTop4,
            child: Text(
              tool.descriptionKey.tr(),
              maxLines: _descriptionMaxLines,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: context.textSoftColor,
              ),
            ),
          )
        : const SizedBox.shrink();

    final content = horizontal
        ? Row(
            children: [
              iconBadge,
              const SizedBox(width: Sizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [title, description],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  iconBadge,
                  if (featured && !horizontal)
                    Container(
                      padding: AppInsets.symmetricH8.add(
                        const EdgeInsets.symmetric(vertical: Sizes.xs),
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(Sizes.xxl),
                      ),
                      child: Text(
                        LocaleKeys.home_featuredBadge.tr(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              title,
              description,
            ],
          );

    return PressScale(
      onTap: onTap,
      child: Container(
        padding: AppInsets.all16,
        decoration: BoxDecoration(
          color: featured ? context.accentSoftColor : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(Sizes.radiusCard),
          border: Border.all(
            color: featured ? theme.colorScheme.primary : context.surfaceBorderColor,
            width: 2,
          ),
        ),
        child: content,
      ),
    );
  }
}
