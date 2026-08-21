part of '../result_panel.dart';

final class _ResultPanelState extends State<ResultPanel>
    with SingleTickerProviderStateMixin {
  static const _popInDuration = Duration(milliseconds: 400);

  late final AnimationController _badgeController = AnimationController(
    vsync: this,
    duration: _popInDuration,
  );
  late final Animation<double> _badgeScale = CurvedAnimation(
    parent: _badgeController,
    curve: Curves.easeOutBack,
  );

  bool _hasAnimated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `prefers-reduced-motion` parity with `design/README.md`'s motion
    // conventions — jump straight to the settled state, no pop.
    if (_hasAnimated) return;
    _hasAnimated = true;
    if (MediaQuery.of(context).disableAnimations) {
      _badgeController.value = 1;
    } else {
      unawaited(_badgeController.forward());
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = widget.tier == ScreenTier.mobile;
    final verticalPadding = isMobile ? Sizes.lg : Sizes.xl;
    final hasComparison =
        widget.beforeSizeInBytes != null && widget.afterSizeInBytes != null;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _badgeScale,
            child: Container(
              width: Sizes.xxl * 2,
              height: Sizes.xxl * 2,
              decoration: BoxDecoration(
                color: context.accentSoftColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: Sizes.xl + Sizes.xs,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: Sizes.lg),
          Text(
            LocaleKeys.result_ready.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: Sizes.xs),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.textSoftColor,
            ),
          ),
          const SizedBox(height: Sizes.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FileInfoRow(
                  fileName: widget.fileName,
                  pageCount: widget.pageCount,
                ),
                if (hasComparison) ...[
                  const SizedBox(height: Sizes.lg),
                  _SizeComparisonRow(
                    beforeSizeInBytes: widget.beforeSizeInBytes!,
                    afterSizeInBytes: widget.afterSizeInBytes!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Sizes.lg),
          _Actions(
            isMobile: isMobile,
            onDownload: widget.onDownload,
            secondaryActionLabel: widget.secondaryActionLabel,
            onSecondaryAction: widget.onSecondaryAction,
          ),
          if (widget.showAutoDeleteNotice) ...[
            const SizedBox(height: Sizes.sm),
            Text(
              LocaleKeys.result_autoDelete.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: context.textSoftColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
