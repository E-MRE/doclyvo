part of '../result_panel.dart';

/// The before/after size blocks. Each block lives inside an [Expanded] rather
/// than a fixed width, so this never rigid-overflows regardless of surface
/// width — the tablet-width overflow trap this shape is prone to (see
/// `apps/native/CLAUDE.md`) comes from fixed-width children, not flexible
/// ones.
final class _SizeComparisonRow extends StatelessWidget {
  const _SizeComparisonRow({
    required this.beforeSizeInBytes,
    required this.afterSizeInBytes,
  });

  final int beforeSizeInBytes;
  final int afterSizeInBytes;

  static const List<String> _unitSymbols = ['B', 'KB', 'MB', 'GB'];
  static const int _unitStep = 1024;

  /// Not localized on purpose, same reasoning as
  /// `PickedPdfFile.formattedSize`: `KB`/`MB`/`GB` read the same in Turkish.
  static String _formatBytes(int bytes) {
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= _unitStep && unitIndex < _unitSymbols.length - 1) {
      size /= _unitStep;
      unitIndex++;
    }
    final fractionDigits = unitIndex == 0 ? 0 : 1;
    return '${size.toStringAsFixed(fractionDigits)} ${_unitSymbols[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final afterFraction = beforeSizeInBytes <= 0
        ? 0.0
        : (afterSizeInBytes / beforeSizeInBytes).clamp(0.0, 1.0);
    final deltaPercent = beforeSizeInBytes <= 0
        ? 0
        : (((afterSizeInBytes - beforeSizeInBytes) / beforeSizeInBytes) * 100)
              .round();
    final sign = deltaPercent > 0 ? '+' : '';
    final afterText = '${_formatBytes(afterSizeInBytes)} · $sign$deltaPercent%';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SizeBlock(
            label: LocaleKeys.result_beforeSize.tr(),
            valueText: _formatBytes(beforeSizeInBytes),
            fraction: 1,
            barColor: context.surfaceBorderColor,
          ),
        ),
        const SizedBox(width: Sizes.lg),
        Expanded(
          child: _SizeBlock(
            label: LocaleKeys.result_afterSize.tr(),
            valueText: afterText,
            fraction: afterFraction,
            barColor: theme.colorScheme.primary,
            valueColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
