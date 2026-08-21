import 'dart:async';
import 'dart:math' as math;
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
import 'package:doclyvo/features/compress/domain/models/compress_quality.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_cubit.dart';
import 'package:doclyvo/features/compress/presentation/cubit/compress_state.dart';
import 'package:doclyvo/features/compress/presentation/widgets/quality_selector.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'compress_screen/_compress_screen_state.dart';
part 'compress_screen/_fake_progress_ticker.dart';
part 'compress_screen/_phase_content.dart';

/// The Compress tool, end to end: upload → quality selection → processing →
/// result/error, composed entirely from the Phase 2 shared widgets and
/// driven by [CompressCubit] over `PdfEngineService` — zero network calls.
final class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}
