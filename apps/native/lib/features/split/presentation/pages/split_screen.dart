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
import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/errors/error_state_widget.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_cubit.dart';
import 'package:doclyvo/features/split/presentation/cubit/split_state.dart';
import 'package:doclyvo/features/split/presentation/widgets/split_page_grid.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'split_screen/_phase_content.dart';
part 'split_screen/_split_screen_state.dart';

/// The Split tool, end to end: upload → (no settings) → processing →
/// result/error, composed from the Phase 2 shared widgets and driven by
/// [SplitCubit] over `PdfEngineService` — zero network calls.
///
/// `design/Split.dc.html` has no settings step (splits into one PDF per
/// page unconditionally), so the idle branch shows a page-count/output
/// summary and a single start action instead of a picker like Compress's
/// `QualitySelector`.
final class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}
