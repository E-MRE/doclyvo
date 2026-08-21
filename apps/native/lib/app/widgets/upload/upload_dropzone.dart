import 'package:desktop_drop/desktop_drop.dart';
import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'upload_dropzone/_dashed_border_painter.dart';
part 'upload_dropzone/_idle_dropzone.dart';
part 'upload_dropzone/_rejection_notice.dart';
part 'upload_dropzone/_selected_file_tile.dart';
part 'upload_dropzone/_upload_dropzone_state.dart';

/// The shared upload surface every tool starts from.
///
/// Two states, straight from `design/Main.dc.html` / `design/MobileHome.dc.html`:
/// an *idle* dashed dropzone with a "Dosya Seç" button, and a *selected* tile
/// showing the file name, its size and a remove button.
///
/// The widget is **controlled**: the caller (a tool cubit, in Phase 3) owns
/// [selectedFile] and reacts to [onFileSelected]/[onFileRemoved]. Only the
/// transient drag-hover and validation-error bits live in local state, so the
/// same instance can be driven from any tool's state machine.
///
/// Drag-drop is wired up on desktop only — on iOS/Android the drop channel does
/// not exist and the file-picker dialog is the single entry point.
final class UploadDropzone extends StatefulWidget {
  const UploadDropzone({
    required this.filePickerService,
    required this.onFileSelected,
    this.selectedFile,
    this.onFileRemoved,
    this.tier = ScreenTier.desktop,
    this.enabled = true,
    super.key,
  });

  /// Comes from `AppDependency.injector` at the feature edge — `core/` never
  /// reaches up into `app/` to resolve it itself.
  final FilePickerService filePickerService;

  /// Called with a validated PDF whenever the user picks or drops one.
  final ValueChanged<PickedPdfFile> onFileSelected;

  /// The file currently held by the caller, or `null` for the idle state.
  final PickedPdfFile? selectedFile;

  /// Called when the user taps the remove button on the selected tile.
  final VoidCallback? onFileRemoved;

  /// The current [ScreenTier]. Only `mobile` gets tighter paddings and a
  /// smaller icon capsule — `tablet` maps to the desktop layout for now.
  final ScreenTier tier;

  /// When `false`, picking and dropping are both ignored (e.g. while a tool is
  /// processing).
  final bool enabled;

  @override
  State<UploadDropzone> createState() => _UploadDropzoneState();
}
