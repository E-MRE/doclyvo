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
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/errors/error_state_widget.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/features/rotate/domain/models/rotate_angle.dart';
import 'package:doclyvo/features/rotate/domain/models/rotate_page_entry.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_cubit.dart';
import 'package:doclyvo/features/rotate/presentation/cubit/rotate_state.dart';
import 'package:doclyvo/features/rotate/presentation/widgets/rotate_page_grid.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'rotate_screen/_rotate_screen_state.dart';
part 'rotate_screen/_phase_content.dart';

/// The Rotate tool, end to end: upload → per-page selection + angle settings
/// → processing → result/error, composed from the Phase 2 shared widgets and
/// driven by [RotateCubit] over `PdfEngineService` — zero network calls.
///
/// Unlike Compress/Split, the idle step also needs per-page previews
/// (`design/Rotate.dc.html`'s selectable grid), streamed in via
/// `PdfEngineService.renderThumbnails` once a file is picked.
final class RotateScreen extends StatefulWidget {
  const RotateScreen({super.key});

  @override
  State<RotateScreen> createState() => _RotateScreenState();
}
