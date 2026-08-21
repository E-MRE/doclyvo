part of '../tool_grid.dart';

final class _ToolCell {
  const _ToolCell(
    this.tool, {
    required this.column,
    required this.row,
    this.columnSpan = 1,
    this.rowSpan = 1,
  });

  final ToolDefinition tool;
  final int column;
  final int row;
  final int columnSpan;
  final int rowSpan;
}
