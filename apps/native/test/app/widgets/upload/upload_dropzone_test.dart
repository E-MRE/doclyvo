// Covers P2-1's dropzone states: idle → selected → removed, plus the visible
// error a non-PDF selection produces.

import 'dart:typed_data';

import 'package:doclyvo/app/widgets/upload/upload_dropzone.dart';
import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_image_file.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widget_test_harness.dart';

/// Stands in for the platform dialog: returns [result], or throws [error].
final class _FakeFilePickerService extends FilePickerService {
  _FakeFilePickerService({this.result, this.error});

  final PickedPdfFile? result;
  final FilePickerException? error;

  @override
  Future<PickedPdfFile?> pickPdf({String? dialogTitle}) async {
    final error = this.error;
    if (error != null) throw error;
    return result;
  }

  @override
  Future<List<PickedPdfFile>> pickMultiplePdfs({String? dialogTitle}) async =>
      throw UnimplementedError();

  @override
  Future<PickedPdfFile> resolveDroppedPath(String path) async =>
      throw UnimplementedError();

  @override
  Future<PickedImageFile?> pickSignatureImage({String? dialogTitle}) async =>
      throw UnimplementedError();

  @override
  Future<bool> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async => throw UnimplementedError();

  @override
  Future<bool> saveZip({
    required String fileName,
    required Uint8List bytes,
  }) async => throw UnimplementedError();
}

PickedPdfFile _pdf({String name = 'rapor-2024.pdf', int size = 9017065}) =>
    PickedPdfFile(
      name: name,
      sizeInBytes: size,
      readBytes: () async => Uint8List(0),
    );

void main() {
  setUpAll(initializeTestLocalization);

  /// Pumps a caller-controlled dropzone, exactly how a tool screen drives it.
  Future<void> pumpDropzone(
    WidgetTester tester, {
    required FilePickerService service,
  }) async {
    PickedPdfFile? selected;

    await pumpLocalized(
      tester,
      (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: UploadDropzone(
              filePickerService: service,
              selectedFile: selected,
              onFileSelected: (file) => setState(() => selected = file),
              onFileRemoved: () => setState(() => selected = null),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('idle state shows the select-file call to action', (
    tester,
  ) async {
    await pumpDropzone(tester, service: _FakeFilePickerService());

    expect(find.text('Dosyanı buraya bırak'), findsOneWidget);
    expect(find.text('Dosya Seç'), findsOneWidget);
    expect(find.text('rapor-2024.pdf'), findsNothing);
  });

  testWidgets('a picked PDF replaces the dropzone with its file tile, and '
      'removing it goes back to idle', (tester) async {
    await pumpDropzone(
      tester,
      service: _FakeFilePickerService(result: _pdf()),
    );

    await tester.tap(find.text('Dosya Seç'));
    await tester.pumpAndSettle();

    expect(find.text('rapor-2024.pdf'), findsOneWidget);
    expect(find.text('8.6 MB'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('rapor-2024.pdf'), findsNothing);
    expect(find.text('Dosya Seç'), findsOneWidget);
  });

  testWidgets('a non-PDF selection surfaces a visible error and stays idle', (
    tester,
  ) async {
    await pumpDropzone(
      tester,
      service: _FakeFilePickerService(
        error: const FilePickerException(
          'not a pdf',
          kind: FilePickerErrorKind.notPdf,
        ),
      ),
    );

    await tester.tap(find.text('Dosya Seç'));
    await tester.pumpAndSettle();

    expect(find.text('Lütfen bir PDF dosyası seçin'), findsOneWidget);
    expect(find.text('Dosya Seç'), findsOneWidget);
  });
}
