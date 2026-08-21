import 'dart:async';

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'progress_indicator/_progress_bar.dart';
part 'progress_indicator/_tool_progress_indicator_state.dart';

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
