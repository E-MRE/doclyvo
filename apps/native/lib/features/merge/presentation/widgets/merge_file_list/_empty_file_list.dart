part of '../merge_file_list.dart';

/// Shown before any file has been added, and while fewer than two files are
/// selected — `design/Merge.dc.html` never draws this state (its placeholder
/// data always has 3 rows), but the tool needs one for a real first run.
final class _EmptyFileList extends StatelessWidget {
  const _EmptyFileList();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppInsets.all24,
      decoration: BoxDecoration(
        border: Border.all(color: context.surfaceBorderColor),
        borderRadius: BorderRadius.circular(Sizes.radiusCard),
      ),
      child: Text(
        LocaleKeys.merge_emptyState.tr(),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: context.textSoftColor),
      ),
    );
  }
}
