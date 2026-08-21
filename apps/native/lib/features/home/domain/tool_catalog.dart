import 'package:doclyvo/app/constants/route_constants.dart';
import 'package:doclyvo/features/home/domain/models/tool_definition.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:flutter/material.dart';

const List<ToolDefinition> kToolCatalog = [
  ToolDefinition(
    id: 'compress',
    titleKey: LocaleKeys.tools_compress,
    descriptionKey: LocaleKeys.toolDescriptions_compress,
    route: RouteConstants.compress,
    icon: Icons.compress,
    featured: true,
  ),
  ToolDefinition(
    id: 'merge',
    titleKey: LocaleKeys.tools_merge,
    descriptionKey: LocaleKeys.toolDescriptions_merge,
    route: RouteConstants.merge,
    icon: Icons.call_merge,
  ),
  ToolDefinition(
    id: 'pdfToWord',
    titleKey: LocaleKeys.tools_pdfToWord,
    descriptionKey: LocaleKeys.toolDescriptions_pdfToWord,
    route: RouteConstants.pdfToWord,
    icon: Icons.description_outlined,
  ),
  ToolDefinition(
    id: 'sign',
    titleKey: LocaleKeys.tools_sign,
    descriptionKey: LocaleKeys.toolDescriptions_sign,
    route: RouteConstants.sign,
    icon: Icons.draw_outlined,
  ),
  ToolDefinition(
    id: 'split',
    titleKey: LocaleKeys.tools_split,
    descriptionKey: LocaleKeys.toolDescriptions_split,
    route: RouteConstants.split,
    icon: Icons.call_split,
  ),
  ToolDefinition(
    id: 'ocr',
    titleKey: LocaleKeys.tools_ocr,
    descriptionKey: LocaleKeys.toolDescriptions_ocr,
    route: RouteConstants.ocr,
    icon: Icons.text_fields,
  ),
  ToolDefinition(
    id: 'protect',
    titleKey: LocaleKeys.tools_protect,
    descriptionKey: LocaleKeys.toolDescriptions_protect,
    route: RouteConstants.protect,
    icon: Icons.lock_outline,
  ),
  ToolDefinition(
    id: 'rotate',
    titleKey: LocaleKeys.tools_rotate,
    descriptionKey: LocaleKeys.toolDescriptions_rotate,
    route: RouteConstants.rotate,
    icon: Icons.rotate_right,
  ),
  ToolDefinition(
    id: 'reorder',
    titleKey: LocaleKeys.tools_reorder,
    descriptionKey: LocaleKeys.toolDescriptions_reorder,
    route: RouteConstants.reorder,
    icon: Icons.grid_view_rounded,
  ),
  ToolDefinition(
    id: 'watermark',
    titleKey: LocaleKeys.tools_watermark,
    descriptionKey: LocaleKeys.toolDescriptions_watermark,
    route: RouteConstants.watermark,
    icon: Icons.branding_watermark_outlined,
  ),
  ToolDefinition(
    id: 'redact',
    titleKey: LocaleKeys.tools_redact,
    descriptionKey: LocaleKeys.toolDescriptions_redact,
    route: RouteConstants.redact,
    icon: Icons.visibility_off_outlined,
  ),
];
