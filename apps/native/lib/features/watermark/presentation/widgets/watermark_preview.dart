import 'dart:math' as math;

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/watermark/domain/models/watermark_opacity.dart';
import 'package:doclyvo/features/watermark/domain/models/watermark_position.dart';
import 'package:flutter/material.dart';

/// The live settings preview from `design/Watermark.dc.html`: the first page
/// rendered as a background, with [text] stamped over it per [position]'s
/// placement/rotation and [opacity]'s alpha — an approximation, not a
/// pixel-accurate render of what `PdfEngineService.addWatermark` will
/// actually produce.
final class WatermarkPreview extends StatelessWidget {
  const WatermarkPreview({
    required this.text,
    required this.position,
    required this.opacity,
    this.pageThumbnail,
    this.tier = ScreenTier.desktop,
    super.key,
  });

  final String text;
  final WatermarkPosition position;
  final WatermarkOpacity opacity;
  final PdfPageThumbnail? pageThumbnail;
  final ScreenTier tier;

  Alignment get _alignment => switch (position) {
    WatermarkPosition.center => Alignment.center,
    WatermarkPosition.diagonal => Alignment.center,
    WatermarkPosition.corner => Alignment.bottomRight,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnail = pageThumbnail;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border.all(color: context.surfaceBorderColor),
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Sizes.radiusButton),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnail != null)
                Image.memory(thumbnail.pngBytes, fit: BoxFit.contain)
              else
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              Padding(
                padding: const EdgeInsets.all(Sizes.lg),
                child: Align(
                  alignment: _alignment,
                  child: Transform.rotate(
                    angle: position.rotation * math.pi / 180,
                    child: Opacity(
                      opacity: text.isEmpty ? 0 : opacity.value,
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
