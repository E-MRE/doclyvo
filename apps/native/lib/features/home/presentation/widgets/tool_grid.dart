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
  static const double _mobileRowHeight = 120;
  static const int _desktopColumns = 4;
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
    // The tablet tier maps to the desktop grid for now — P1-5 designs its own.
    final isMobile = tier == ScreenTier.mobile;
    final cells = isMobile ? _mobileCells : _desktopCells;
    final columns = isMobile ? _mobileColumns : _desktopColumns;
    final rowHeight = isMobile ? _mobileRowHeight : _desktopRowHeight;
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
                    horizontal: isMobile && cell.columnSpan > 1,
                    showDescription: !isMobile,
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
