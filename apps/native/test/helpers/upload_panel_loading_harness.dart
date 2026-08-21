// Shared setup for the "upload panel tracks the cubit's Loading state" tests.
//
// The regression these guard against: a tool screen that reads `_cubit.state`
// inside `_buildUploadPanel()` — which runs from `build()`, not from a
// `BlocBuilder` — computes `UploadDropzone.enabled` once and never again.
// `build()` only re-runs on `setState`, and a cubit emission does not trigger
// one, so the dropzone stays interactive for the whole operation: the user can
// drop a second file (or hit remove) mid-run, the screen resets, and the
// in-flight call then lands a result for a file that is no longer selected.
//
// Each test drives its screen's cubit into Loading through a repository whose
// operation never completes, then asserts the panel reacted. No file picking
// or button tapping is involved on purpose — the bug is about rebuild
// plumbing, not about the flow that reaches it.
//
// Confirmed affected when these tests were written: Split, Merge, Rotate,
// Reorder, Watermark. Compress was not — see the note in its own test.

import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/theme/app_theme.dart';
import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test_harness.dart';

/// Replaces an already-registered dependency with [factory].
///
/// Registering a closure over a single instance turns the app's factory
/// registration into a de-facto singleton, which is what lets a test hold the
/// very cubit the screen resolves in `initState`.
Future<void> overrideDependency<T extends Object>(T Function() factory) async {
  await AppDependency.injector.unregister<T>();
  AppDependency.injector.registerFactory<T>(factory);
}

/// Pumps [screen] at a desktop width under the real localization + DI graph.
///
/// The 900px height matches the tool screens' width-sweep tests rather than
/// `kDesktopTestSurface`'s 1024 — see the Merge note in
/// `merge_screen_loading_panel_test.dart`.
Future<void> pumpToolScreen(
  WidgetTester tester,
  Widget screen, {
  Size surfaceSize = const Size(1440, 900),
}) {
  return pumpLocalized(
    tester,
    (context) => MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: screen,
    ),
    surfaceSize: surfaceSize,
  );
}

/// Fails unless the screen's dropzone is currently locked down.
///
/// `enabled` is a real interaction gate, not decoration: `UploadDropzone`
/// checks it before picking, before accepting a drop, and before offering the
/// remove button.
void expectDropzoneDisabled(WidgetTester tester) => expectPanelDisabled(
  enabled: tester.widget<UploadDropzone>(find.byType(UploadDropzone)).enabled,
);

/// The same assertion for a screen whose input panel is not an
/// `UploadDropzone` — Merge gates its `MergeFileList` instead.
void expectPanelDisabled({required bool enabled}) {
  expect(
    enabled,
    isFalse,
    reason:
        'the input panel did not rebuild when the cubit emitted Loading — '
        'it is reading cubit.state outside a BlocBuilder',
  );
}
