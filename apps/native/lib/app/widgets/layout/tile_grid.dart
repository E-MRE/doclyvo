import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

/// A fixed-column tile grid that can be measured by an `IntrinsicHeight`.
///
/// The obvious way to write this is a shrink-wrapped `GridView`, and that is
/// what Rotate, Split and Reorder originally used — but every tool screen's
/// desktop branch puts its panels inside `IntrinsicHeight(Row(...))`, and a
/// `GridView` is a viewport: asked for an intrinsic dimension it trips
/// `debugThrowIfNotCheckingIntrinsics()` and the screen dies the moment a file
/// is picked and the grid appears. `shrinkWrap: true` does not help — a
/// `RenderShrinkWrappingViewport` refuses intrinsics just as flatly.
///
/// This is the same trap `ToolProgressIndicator`'s bar and `ResultPanel`'s size
/// block hit with `LayoutBuilder` (see the note on `_ProgressBar`), one layer
/// deeper: anything that answers "I need my own constraints first" cannot live
/// in a tool screen's desktop column.
///
/// So the grid is laid out with plain flex instead: a `Column` of `Row`s whose
/// cells are `Expanded(AspectRatio(...))`. `RenderFlex` and `RenderAspectRatio`
/// both implement intrinsics, the cells still share the row width evenly, and
/// there is no scrolling to shrink-wrap — the caller's `SingleChildScrollView`
/// already scrolls.
///
/// The last row is padded with empty cells so its tiles keep the column width
/// the full rows use, instead of stretching across the leftover space.
final class TileGrid extends StatelessWidget {
  const TileGrid({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.children,
    this.spacing = Sizes.sm,
    super.key,
  }) : assert(crossAxisCount > 0, 'a grid needs at least one column');

  final int crossAxisCount;

  /// Width / height of each tile, matching `SliverGridDelegate`'s meaning.
  final double childAspectRatio;

  final List<Widget> children;

  /// Gap between tiles, both directions.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += crossAxisCount) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(_buildRow(start));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildRow(int start) {
    final cells = <Widget>[];
    for (var column = 0; column < crossAxisCount; column++) {
      if (column > 0) cells.add(SizedBox(width: spacing));

      final index = start + column;
      cells.add(
        Expanded(
          child: index < children.length
              ? AspectRatio(
                  aspectRatio: childAspectRatio,
                  child: children[index],
                )
              : const SizedBox.shrink(),
        ),
      );
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells);
  }
}
