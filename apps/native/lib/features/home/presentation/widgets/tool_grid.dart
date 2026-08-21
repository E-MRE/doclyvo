import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/home/domain/models/tool_definition.dart';
import 'package:doclyvo/features/home/domain/tool_catalog.dart';
import 'package:doclyvo/features/home/presentation/widgets/tool_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'tool_grid/_tool_cell.dart';

final class ToolGrid extends StatelessWidget {
  const ToolGrid({required this.tier, super.key});

  static const double _desktopRowHeight = 150;
  static const double _tabletRowHeight = 140;
  static const double _mobileRowHeight = 120;
  static const int _desktopColumns = 4;
  static const int _tabletColumns = 3;
  static const int _mobileColumns = 2;

  final ScreenTier tier;

  List<_ToolCell> get _desktopCells => [
    _ToolCell(kToolCatalog[0], column: 0, row: 0, columnSpan: 2, rowSpan: 2),
    _ToolCell(kToolCatalog[1], column: 2, row: 0),
    _ToolCell(kToolCatalog[2], column: 3, row: 0),
    _ToolCell(kToolCatalog[3], column: 2, row: 1),
    _ToolCell(kToolCatalog[4], column: 3, row: 1),
    _ToolCell(kToolCatalog[5], column: 0, row: 2),
    _ToolCell(kToolCatalog[6], column: 1, row: 2),
    _ToolCell(kToolCatalog[7], column: 2, row: 2),
    _ToolCell(kToolCatalog[8], column: 3, row: 2),
    _ToolCell(kToolCatalog[9], column: 0, row: 3),
    _ToolCell(kToolCatalog[10], column: 1, row: 3),
  ];

  /// 3 columns, not 4 squeezed or 2 stretched — see the P1-5 Decisions log
  /// entry in NATIVE-TASKS.md. Compress keeps its "featured" treatment as a
  /// full-width horizontal banner (like mobile's, not desktop's 2x2 block,
  /// which would leave an awkward single column beside it in a 3-column
  /// grid); Redact, the 11th tool, gets the same full-width banner rather
  /// than an unbalanced lone cell.
  List<_ToolCell> get _tabletCells => [
    _ToolCell(kToolCatalog[0], column: 0, row: 0, columnSpan: 3),
    _ToolCell(kToolCatalog[1], column: 0, row: 1),
    _ToolCell(kToolCatalog[2], column: 1, row: 1),
    _ToolCell(kToolCatalog[3], column: 2, row: 1),
    _ToolCell(kToolCatalog[4], column: 0, row: 2),
    _ToolCell(kToolCatalog[5], column: 1, row: 2),
    _ToolCell(kToolCatalog[6], column: 2, row: 2),
    _ToolCell(kToolCatalog[7], column: 0, row: 3),
    _ToolCell(kToolCatalog[8], column: 1, row: 3),
    _ToolCell(kToolCatalog[9], column: 2, row: 3),
    _ToolCell(kToolCatalog[10], column: 0, row: 4, columnSpan: 3),
  ];

  List<_ToolCell> get _mobileCells => [
    _ToolCell(kToolCatalog[0], column: 0, row: 0, columnSpan: 2),
    _ToolCell(kToolCatalog[1], column: 0, row: 1),
    _ToolCell(kToolCatalog[2], column: 1, row: 1),
    _ToolCell(kToolCatalog[3], column: 0, row: 2),
    _ToolCell(kToolCatalog[4], column: 1, row: 2),
    _ToolCell(kToolCatalog[5], column: 0, row: 3),
    _ToolCell(kToolCatalog[6], column: 1, row: 3),
    _ToolCell(kToolCatalog[7], column: 0, row: 4),
    _ToolCell(kToolCatalog[8], column: 1, row: 4),
    _ToolCell(kToolCatalog[9], column: 0, row: 5),
    _ToolCell(kToolCatalog[10], column: 0, row: 6, columnSpan: 2),
  ];

  @override
  Widget build(BuildContext context) {
    final cells = switch (tier) {
      ScreenTier.mobile => _mobileCells,
      ScreenTier.tablet => _tabletCells,
      ScreenTier.desktop => _desktopCells,
    };
    final columns = switch (tier) {
      ScreenTier.mobile => _mobileColumns,
      ScreenTier.tablet => _tabletColumns,
      ScreenTier.desktop => _desktopColumns,
    };
    final rowHeight = switch (tier) {
      ScreenTier.mobile => _mobileRowHeight,
      ScreenTier.tablet => _tabletRowHeight,
      ScreenTier.desktop => _desktopRowHeight,
    };
    // Tablet's wider columns fit a description under the title (unlike
    // mobile's ~173px cells) — see the P1-5 Decisions log entry.
    final showDescription = tier != ScreenTier.mobile;
    const gap = Sizes.lg;
    final rowCount = cells
        .map((cell) => cell.row + cell.rowSpan)
        .reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth =
            (constraints.maxWidth - (columns - 1) * gap) / columns;

        return SizedBox(
          height: rowCount * rowHeight + (rowCount - 1) * gap,
          child: Stack(
            children: [
              for (final cell in cells)
                Positioned(
                  left: cell.column * (columnWidth + gap),
                  top: cell.row * (rowHeight + gap),
                  width:
                      cell.columnSpan * columnWidth +
                      (cell.columnSpan - 1) * gap,
                  height:
                      cell.rowSpan * rowHeight + (cell.rowSpan - 1) * gap,
                  child: ToolCard(
                    tool: cell.tool,
                    horizontal:
                        tier != ScreenTier.desktop && cell.columnSpan > 1,
                    showDescription: showDescription,
                    onTap: () => context.go(cell.tool.route),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
