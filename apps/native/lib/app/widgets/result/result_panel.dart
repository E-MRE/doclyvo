import 'dart:async';

import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/app/widgets/buttons/secondary_button.dart';
import 'package:doclyvo/app/widgets/cards/app_card.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

part 'result_panel/_actions.dart';
part 'result_panel/_file_info_row.dart';
part 'result_panel/_result_panel_state.dart';
part 'result_panel/_size_block.dart';
part 'result_panel/_size_comparison_row.dart';

/// The success state shared by all 11 tool screens, from
/// `design/Result.dc.html` / `design/MobileResult.dc.html`: a pop-in success
/// badge, a before/after file size comparison, a download button and an
/// optional secondary action, plus a conditional 24-hour auto-delete notice.
///
/// Lives in `lib/app/widgets/` rather than `lib/core/widgets/` for the same
/// reason `UploadDropzone` and `ToolProgressIndicator` do (see the P2-1
/// Decisions log entry in `NATIVE-TASKS.md`): it needs `BuildContextExtension`
/// and the `PrimaryButton`/`SecondaryButton`/`AppCard` widgets, all in
/// `lib/app/`, and `core/` may not import `app/`.
///
/// [beforeSizeInBytes]/[afterSizeInBytes] must be supplied together or not at
/// all — the comparison card only renders when both are known. Byte sizes are
/// formatted the same way `PickedPdfFile.formattedSize` does (`KB`/`MB`/`GB`,
/// not localized — the unit symbols read the same in Turkish).
///
/// [showAutoDeleteNotice] is caller-controlled rather than inferred here: it
/// only makes sense for Phase 3B (backend-processed) results, never for
/// Phase 3A files that never left the device.
final class ResultPanel extends StatefulWidget {
  const ResultPanel({
    required this.message,
    required this.fileName,
    required this.onDownload,
    this.pageCount,
    this.beforeSizeInBytes,
    this.afterSizeInBytes,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showAutoDeleteNotice = false,
    this.tier = ScreenTier.desktop,
    super.key,
  }) : assert(
         (beforeSizeInBytes == null) == (afterSizeInBytes == null),
         'beforeSizeInBytes and afterSizeInBytes must be supplied together',
       ),
       assert(
         (secondaryActionLabel == null) == (onSecondaryAction == null),
         'secondaryActionLabel and onSecondaryAction must be supplied '
         'together',
       );

  /// Subtitle under the "Dosyan hazır" heading, e.g.
  /// "rapor-2024.pdf sıkıştırıldı ve indirilmeye hazır." Tool-specific copy,
  /// owned by the caller.
  final String message;

  /// The output file's name, shown in the file info row.
  final String fileName;

  /// Fires when the download button is tapped. Actually saving the bytes to
  /// disk (share-sheet, downloads dir, file-save dialog) is the caller's job
  /// — the bytes source differs between Phase 3A/3B.
  final VoidCallback onDownload;

  /// Page count shown under the file name, when known.
  final int? pageCount;

  /// Size of the input file, in bytes. Must be supplied together with
  /// [afterSizeInBytes] or not at all.
  final int? beforeSizeInBytes;

  /// Size of the output file, in bytes.
  final int? afterSizeInBytes;

  /// Label for an optional second action (e.g. "Bağlantıyı Kopyala"). Must be
  /// supplied together with [onSecondaryAction] or not at all.
  final String? secondaryActionLabel;

  final VoidCallback? onSecondaryAction;

  /// Shows the "deleted after 24 hours" notice. Only meaningful for
  /// backend-processed (Phase 3B) results.
  final bool showAutoDeleteNotice;

  /// The current [ScreenTier]. Only `mobile` stacks the actions vertically —
  /// `tablet` maps to the desktop layout for now.
  final ScreenTier tier;

  @override
  State<ResultPanel> createState() => _ResultPanelState();
}
