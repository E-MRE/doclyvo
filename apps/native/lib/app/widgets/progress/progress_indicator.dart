import 'dart:async';

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The processing state shared by all 11 tool screens, from
/// `design/Compress.dc.html`'s `isProcessing` branch: a status line with the
/// live percentage, a hint below it, then a determinate bar whose fill has a
/// looping shimmer sweep.
///
/// Lives in `lib/app/widgets/` rather than `lib/core/widgets/` for the same
/// reason `UploadDropzone` does (see the P2-1 Decisions log entry in
/// `NATIVE-TASKS.md`): it needs `BuildContextExtension`'s `textSoftColor`,
/// and `core/` may not import `app/`.
///
/// [progress] is 0-100 and may come from a real upload/processing duration
/// (Phase 3B) or a simulated one (Phase 3A, mirroring `apps/web`'s
/// `useFakeProgress` hook) — the widget only renders it, callers own how it
/// ticks. Percentage and bar width both animate smoothly between updates
/// rather than jumping.
final class ToolProgressIndicator extends StatefulWidget {
  const ToolProgressIndicator({
    required this.progress,
    this.label,
    this.hint,
    this.tier = ScreenTier.desktop,
    super.key,
  });

  /// Current progress, clamped to 0-100.
  final double progress;

  /// Status text shown before the percentage, e.g. "Sıkıştırılıyor…".
  /// Defaults to the generic `progress.processing` copy.
  final String? label;

  /// Small hint line below the status text. Defaults to the generic
  /// `progress.hint` copy ("Bu işlem birkaç saniye sürebilir.").
  final String? hint;

  /// The current [ScreenTier]. Only `mobile` gets tighter vertical padding —
  /// `tablet` maps to the desktop spacing.
  final ScreenTier tier;

  @override
  State<ToolProgressIndicator> createState() => _ToolProgressIndicatorState();
}

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

/// The determinate bar itself, split out so the shimmer's `AnimatedBuilder`
/// only rebuilds this small subtree, not the surrounding text.
final class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progressFraction,
    required this.shimmerController,
    required this.trackColor,
    required this.fillColor,
    required this.height,
  });

  /// 0.0-1.0.
  final double progressFraction;

  /// `null` when `prefers-reduced-motion` is on — no shimmer overlay at all.
  final AnimationController? shimmerController;

  final Color trackColor;
  final Color fillColor;
  final double height;

  static const double _shimmerWidthFraction = 0.35;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filledWidth = constraints.maxWidth * progressFraction;

          return SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(color: trackColor),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: filledWidth,
                  height: height,
                  color: fillColor,
                  child: shimmerController == null
                      ? null
                      : ClipRect(
                          child: AnimatedBuilder(
                            animation: shimmerController!,
                            builder: (context, _) {
                              final shimmerWidth =
                                  filledWidth * _shimmerWidthFraction;
                              final travel = filledWidth + shimmerWidth;
                              final dx =
                                  shimmerController!.value * travel -
                                  shimmerWidth;

                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: Container(
                                  width: shimmerWidth,
                                  height: height,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0),
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.white.withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
