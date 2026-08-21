part of '../progress_indicator.dart';

/// The determinate bar itself, split out so the shimmer's `AnimatedBuilder`
/// only rebuilds this small subtree, not the surrounding text.
///
/// Everything here is expressed as a *fraction* of the available width rather
/// than measured with a `LayoutBuilder`. That is not a style preference: every
/// tool screen's desktop layout puts this widget inside an `IntrinsicHeight`
/// (the two-column upload/settings row), and `IntrinsicHeight` throws
/// "LayoutBuilder does not support returning intrinsic dimensions" the moment
/// it tries to measure one. `FractionallySizedBox`/`FractionalTranslation`
/// answer intrinsic queries fine.
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

  /// The shimmer sweeps from just before the filled area to just past it.
  ///
  /// In pixels that run is `filled + shimmer` wide starting at `-shimmer`;
  /// divided through by the shimmer's own width — which is what
  /// [FractionalTranslation] offsets by — it collapses to this constant.
  static const double _shimmerTravelFactor = 1 + 1 / _shimmerWidthFraction;

  @override
  Widget build(BuildContext context) {
    final controller = shimmerController;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: trackColor),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressFraction.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              color: fillColor,
              child: controller == null
                  ? null
                  : ClipRect(
                      child: AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) => FractionalTranslation(
                          translation: Offset(
                            controller.value * _shimmerTravelFactor - 1,
                            0,
                          ),
                          child: child,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _shimmerWidthFraction,
                          child: DecoratedBox(
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
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
