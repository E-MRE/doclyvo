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
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/core/widgets/errors/error_state_widget.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_image_file.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/features/sign/domain/models/signature_mode.dart';
import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';
import 'package:doclyvo/features/sign/domain/services/signature_image_renderer.dart';
import 'package:doclyvo/features/sign/presentation/cubit/sign_cubit.dart';
import 'package:doclyvo/features/sign/presentation/cubit/sign_state.dart';
import 'package:doclyvo/features/sign/presentation/widgets/sign_document_preview.dart';
import 'package:doclyvo/features/sign/presentation/widgets/signature_mode_tabs.dart';
import 'package:doclyvo/features/sign/presentation/widgets/signature_pad.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'sign_screen/_sign_screen_state.dart';
part 'sign_screen/_phase_content.dart';

/// The Sign tool, end to end: upload → signature (draw / type / upload PNG) →
/// place → processing → result/error, composed from the Phase 2 shared widgets
/// and driven by [SignCubit] over `PdfEngineService` — zero network calls.
///
/// Visual placement only, by design: `apps/web`'s Sign also writes an
/// append-only audit log for signed-in users, which needs auth plus Postgres.
/// Native MVP has no login, and calling the backend would break the Phase 3A
/// "these eight tools work fully offline" rule — so audit-log parity is
/// deferred, deliberately. See the P3A-8 Decisions log entry in
/// `NATIVE-TASKS.md`.
final class SignScreen extends StatefulWidget {
  const SignScreen({super.key});

  @override
  State<SignScreen> createState() => _SignScreenState();
}
