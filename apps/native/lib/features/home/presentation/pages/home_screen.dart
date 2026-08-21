import 'dart:async';

import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/constants/responsive_constants.dart';
import 'package:doclyvo/app/extensions/build_context_extension.dart';
import 'package:doclyvo/app/theme/theme_service.dart';
import 'package:doclyvo/core/utils/constants/app_insets.dart';
import 'package:doclyvo/core/utils/constants/sizes.dart';
import 'package:doclyvo/features/home/presentation/cubit/home_cubit.dart';
import 'package:doclyvo/features/home/presentation/widgets/home_header.dart';
import 'package:doclyvo/features/home/presentation/widgets/home_hero_section.dart';
import 'package:doclyvo/features/home/presentation/widgets/tool_grid.dart';
import 'package:doclyvo/features/home/presentation/widgets/upload_preview_card.dart';
import 'package:doclyvo/generated/localization/lang/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_screen/_home_screen_state.dart';
part 'home_screen/_tools_section.dart';

final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
