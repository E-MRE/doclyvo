// Shared bootstrapping for widget tests that pump real screens.
//
// Two things every such test needs and none of them get for free:
//
// 1. `AppDependency` registrations. Screens resolve `ThemeService`/`HomeCubit`
//    from GetIt in `initState`, which `AppInitializer` sets up at app start —
//    a test that skips it dies with "not registered inside GetIt".
// 2. A live `EasyLocalization`. Its translation asset is read off the *real*
//    event loop, so `pumpAndSettle` alone can finish before the Turkish copy
//    is in place; the pump has to happen inside `runAsync`.

import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/app/widgets/wrappers/localization_wrapper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots `EasyLocalization` — call from `setUpAll`.
///
/// It reads the saved locale through `shared_preferences`, whose platform
/// channel does not exist in a test, so the mock store has to be primed first.
Future<void> initializeTestLocalization() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

final class _TestRegistrar with AppDependencyRegisterMixin {}

/// Registers the app's real dependency graph — call from `setUp`.
void registerAppDependencies() =>
    _TestRegistrar().registerDependencies(AppDependency.injector);

/// Tears the graph down again — call from `tearDown`, or GetIt leaks
/// registrations into the next test.
Future<void> resetAppDependencies() => AppDependency.injector.reset();

/// A desktop surface wide enough for the real desktop layouts.
///
/// Widget tests default to 800x600, which sits *above* the 700px mobile
/// breakpoint but is far narrower than the 1440px the desktop designs are drawn
/// for — so screens render their desktop branch into a phone-sized box and
/// overflow. Pumping at the design width tests the layout that ships.
const Size kDesktopTestSurface = Size(1440, 1024);

/// Pumps the widget [builder] returns under a live `EasyLocalization`, then
/// settles.
///
/// [builder] receives a context below the `EasyLocalization` ancestor, so a
/// `MaterialApp` it creates can read `context.localizationDelegates`. Pass
/// [surfaceSize] to exercise a different breakpoint.
///
/// Pass `settle: false` for a tree that never goes idle — the progress bar's
/// shimmer and the page grids' placeholder animations repeat forever, so
/// `pumpAndSettle` times out on a perfectly healthy widget. The `runAsync`
/// pump above still happens, which is the part that gets the Turkish copy in
/// place, so the alternative of hand-rolling `pumpWidget(EasyLocalization(…))`
/// is never the right call: past the first test in a file it silently renders
/// nothing.
Future<void> pumpLocalized(
  WidgetTester tester,
  WidgetBuilder builder, {
  Size surfaceSize = kDesktopTestSurface,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = surfaceSize
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tree = LocalizationWrapper(child: Builder(builder: builder));

  await tester.runAsync(() async {
    await tester.pumpWidget(tree);
    await Future<void>.delayed(Duration.zero);
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}
