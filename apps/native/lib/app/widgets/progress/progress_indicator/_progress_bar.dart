part of '../progress_indicator.dart';

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
