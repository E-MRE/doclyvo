// Covers P2-1's PDF-only gate: the same validation guards both entry points
// (dialog and desktop drag-drop), and the service resolves through
// AppDependency as its abstract type so features never name the picker package.

import 'dart:io';

import 'package:doclyvo/app/app_dependency.dart';
import 'package:doclyvo/app/utils/mixins/app_dependency_register_mixin.dart';
import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:doclyvo/core/widgets/upload/platform_file_picker_manager.dart';
import 'package:flutter_test/flutter_test.dart';

final class _TestRegistrar with AppDependencyRegisterMixin {}

void main() {
  const service = PlatformFilePickerManager();

  group('isPdfFileName', () {
    test('accepts a .pdf name regardless of case', () {
      expect(service.isPdfFileName('rapor-2024.pdf'), isTrue);
      expect(service.isPdfFileName('RAPOR.PDF'), isTrue);
    });

    test('rejects anything else', () {
      expect(service.isPdfFileName('rapor.docx'), isFalse);
      expect(service.isPdfFileName('pdf'), isFalse);
      expect(service.isPdfFileName('rapor.pdf.zip'), isFalse);
    });
  });

  group('resolveDroppedPath', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('dropzone_test');
    });

    tearDown(() async {
      await tempDirectory.delete(recursive: true);
    });

    test('rejects a non-PDF drop before touching the disk', () async {
      await expectLater(
        service.resolveDroppedPath('${tempDirectory.path}/rapor.docx'),
        throwsA(
          isA<FilePickerException>().having(
            (error) => error.kind,
            'kind',
            FilePickerErrorKind.notPdf,
          ),
        ),
      );
    });

    test('rejects a .pdf path that is not a readable file', () async {
      await expectLater(
        service.resolveDroppedPath('${tempDirectory.path}/missing.pdf'),
        throwsA(
          isA<FilePickerException>().having(
            (error) => error.kind,
            'kind',
            FilePickerErrorKind.unreadable,
          ),
        ),
      );
    });

    test('resolves a real PDF into a PickedPdfFile with readable bytes',
        () async {
      final path = '${tempDirectory.path}/rapor-2024.pdf';
      final bytes = List<int>.filled(2048, 0x25);
      await File(path).writeAsBytes(bytes);

      final picked = await service.resolveDroppedPath(path);

      expect(picked.name, 'rapor-2024.pdf');
      expect(picked.sizeInBytes, bytes.length);
      expect(picked.path, path);
      expect(await picked.readBytes(), hasLength(bytes.length));
    });
  });

  group('formattedSize', () {
    PickedPdfFile fileOfSize(int sizeInBytes) => PickedPdfFile(
      name: 'rapor.pdf',
      sizeInBytes: sizeInBytes,
      readBytes: () async => throw UnimplementedError(),
    );

    test('renders bytes whole and larger units with one decimal', () {
      expect(fileOfSize(512).formattedSize, '512 B');
      expect(fileOfSize(1024).formattedSize, '1.0 KB');
      expect(fileOfSize(9017065).formattedSize, '8.6 MB');
    });
  });

  group('dependency injection', () {
    tearDown(() async {
      await AppDependency.injector.reset();
    });

    test('FilePickerService resolves as a shared instance', () {
      _TestRegistrar().registerDependencies(AppDependency.injector);

      final picker = AppDependency.injector.get<FilePickerService>();

      expect(picker, isA<PlatformFilePickerManager>());
      expect(AppDependency.injector.get<FilePickerService>(), same(picker));
    });
  });
}
