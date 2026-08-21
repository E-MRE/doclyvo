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
import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/errors/error_state_widget.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/features/protect/domain/models/protect_permission.dart';
import 'package:doclyvo/features/protect/domain/services/password_generator.dart';
import 'package:doclyvo/features/protect/presentation/cubit/protect_cubit.dart';
import 'package:doclyvo/features/protect/presentation/cubit/protect_state.dart';
import 'package:doclyvo/features/protect/presentation/widgets/protect_lock_status.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'protect_screen/_protect_screen_state.dart';
part 'protect_screen/_phase_content.dart';

/// The Protect tool, end to end: upload → password + permission settings →
/// processing → result/error, composed from the Phase 2 shared widgets and
/// driven by [ProtectCubit] over `PdfEngineService` — zero network calls.
///
/// Protect-only by design: `PdfEngineService` can also strip encryption, but
/// `apps/web`'s Protect tool is one-way and native MVP matches it (see the
/// P3A-7 Decisions log entry in `NATIVE-TASKS.md`).
final class ProtectScreen extends StatefulWidget {
  const ProtectScreen({super.key});

  @override
  State<ProtectScreen> createState() => _ProtectScreenState();
}
