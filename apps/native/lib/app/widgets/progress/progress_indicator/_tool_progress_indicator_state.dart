part of '../progress_indicator.dart';

final class _ToolProgressIndicatorState extends State<ToolProgressIndicator>
    with SingleTickerProviderStateMixin {
  static const _shimmerDuration = Duration(milliseconds: 1300);
  static const _percentTweenDuration = Duration(milliseconds: 250);
  static const double _barHeight = Sizes.sm;

  late final AnimationController _shimmerController = AnimationController(
    vsync: this,
    duration: _shimmerDuration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `prefers-reduced-motion` parity with `design/README.md`'s motion
    // conventions — no shimmer ticking at all, not just a hidden overlay.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      if (_shimmerController.isAnimating) _shimmerController.stop();
    } else if (!_shimmerController.isAnimating) {
      unawaited(_shimmerController.repeat());
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final clampedProgress = widget.progress.clamp(0, 100).toDouble();
    final verticalPadding = widget.tier == ScreenTier.mobile
        ? Sizes.lg
        : Sizes.xl;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: clampedProgress),
        duration: _percentTweenDuration,
        builder: (context, animatedProgress, _) {
          final percent = animatedProgress.round().clamp(0, 100);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.label ?? LocaleKeys.progress_processing.tr()} '
                '${LocaleKeys.progress_percent.tr(namedArgs: {
                  'percent': '$percent',
                })}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Sizes.xs),
              Text(
                widget.hint ?? LocaleKeys.progress_hint.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.textSoftColor,
                ),
              ),
              const SizedBox(height: Sizes.lg),
              _ProgressBar(
                progressFraction: animatedProgress / 100,
                shimmerController: reduceMotion ? null : _shimmerController,
                trackColor: theme.scaffoldBackgroundColor,
                fillColor: theme.colorScheme.primary,
                height: _barHeight,
              ),
            ],
          );
        },
      ),
    );
  }
}
