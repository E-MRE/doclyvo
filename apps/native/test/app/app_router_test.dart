import 'dart:async';

import 'package:doclyvo/app/app_router.dart';
import 'package:doclyvo/app/constants/route_constants.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/features/compress/presentation/pages/compress_screen.dart';
import 'package:doclyvo/features/home/presentation/pages/home_screen.dart';
import 'package:doclyvo/features/merge/presentation/pages/merge_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  setUpAll(initializeTestLocalization);

  setUp(() {
    registerAppDependencies();
    router.go(RouteConstants.home);
  });

  tearDown(resetAppDependencies);

  Future<void> pumpRouter(WidgetTester tester) => pumpLocalized(
    tester,
    (context) => MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    ),
  );

  testWidgets('boots to the home screen', (tester) async {
    await pumpRouter(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('navigates to a tool route with a fade-in-up transition', (
    tester,
  ) async {
    await pumpRouter(tester);

    unawaited(router.push(RouteConstants.compress));
    await tester.pump();

    expect(find.byType(Opacity), findsWidgets);

    await tester.pumpAndSettle();

    // Compress has a real screen now (P3A-1) instead of the placeholder, so
    // this checks for the screen type rather than a literal "Compress"
    // heading, which is no longer rendered anywhere on it.
    expect(find.byType(CompressScreen), findsOneWidget);
  });

  testWidgets('back navigation returns to the previous route', (tester) async {
    await pumpRouter(tester);

    unawaited(router.push(RouteConstants.merge));
    await tester.pumpAndSettle();
    // Merge has a real screen now (P3A-3) instead of the placeholder, so
    // this checks for the screen type rather than a literal "Merge"
    // heading, which is no longer rendered anywhere on it.
    expect(find.byType(MergeScreen), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
