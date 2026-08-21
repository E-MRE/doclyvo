import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/constants/route_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/app/widgets/cards/app_card.dart';
import 'package:doclyvo/app/widgets/progress/progress_indicator.dart';
import 'package:doclyvo/app/widgets/result/result_panel.dart';
import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/errors/error_state_widget.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/features/merge/domain/models/merge_file_entry.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_cubit.dart';
import 'package:doclyvo/features/merge/presentation/cubit/merge_state.dart';
import 'package:doclyvo/features/merge/presentation/widgets/merge_file_list.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'merge_screen/_merge_screen_state.dart';
part 'merge_screen/_phase_content.dart';

/// The Merge tool, end to end: multi-file upload → reorderable list →
/// processing → result/error, composed from the Phase 2 shared widgets and
/// driven by [MergeCubit] over `PdfEngineService` — zero network calls.
///
/// Unlike Compress/Split, `design/Merge.dc.html` has no single-file
/// dropzone at all — the whole idle state is the reorderable file list plus
/// an "add files" action (see `MergeFileList`) — so this screen never uses
/// `UploadDropzone`.
final class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}
