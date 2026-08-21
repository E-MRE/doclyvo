import 'dart:async';
import 'dart:typed_data';

import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/constants/route_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/widgets/buttons/primary_button.dart';
import 'package:doclyvo/app/widgets/buttons/secondary_button.dart';
import 'package:doclyvo/app/widgets/cards/app_card.dart';
import 'package:doclyvo/app/widgets/progress/progress_indicator.dart';
import 'package:doclyvo/app/widgets/result/result_panel.dart';
import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/pdf/models/pdf_page_thumbnail.dart';
import 'package:doclyvo/core/pdf/models/pdf_watermark_options.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/errors/error_state_widget.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/features/watermark/domain/models/watermark_opacity.dart';
import 'package:doclyvo/features/watermark/domain/models/watermark_position.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_cubit.dart';
import 'package:doclyvo/features/watermark/presentation/cubit/watermark_state.dart';
import 'package:doclyvo/features/watermark/presentation/widgets/watermark_preview.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'watermark_screen/_watermark_screen_state.dart';
part 'watermark_screen/_phase_content.dart';

/// The Watermark tool, end to end: upload → live preview + text/position/
/// opacity settings → processing → result/error, composed from the Phase 2
/// shared widgets and driven by [WatermarkCubit] over `PdfEngineService` —
/// zero network calls.
///
/// The idle step's preview reuses `PdfEngineService.renderThumbnails` on just
/// the first page (`design/Watermark.dc.html`'s preview pane), per the
/// Phase 3A table's note for this tool.
final class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}
