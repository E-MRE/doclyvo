import 'dart:io';
import 'dart:typed_data';

import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/widgets/upload/file_picker_service.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';
import 'package:file_picker/file_picker.dart';

/// [FilePickerService] backed by the platform's native picker dialog.
///
/// Stateless and cheap to construct — it holds no handles, so it is registered
/// as a lazy singleton purely to avoid re-allocating it per screen.
final class PlatformFilePickerManager extends FilePickerService {
  const PlatformFilePickerManager();

  @override
  Future<PickedPdfFile?> pickPdf({String? dialogTitle}) async {
    PlatformFile? file;
    try {
      file = await FilePicker.pickFile(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: const [FilePickerService.pdfExtension],
      );
    } on Exception catch (error) {
      throw FilePickerException('$error');
    }

    if (file == null) return null;

    // The dialog already filters by extension, but Android content providers
    // and "All files" escape hatches can still hand back something else.
    if (!isPdfFileName(file.name)) {
      throw FilePickerException(
        'Picked file is not a PDF: ${file.name}',
        kind: FilePickerErrorKind.notPdf,
      );
    }

    return _toPickedFile(file);
  }

  @override
  Future<List<PickedPdfFile>> pickMultiplePdfs({String? dialogTitle}) async {
    List<PlatformFile> files;
    try {
      files = await FilePicker.pickFiles(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: const [FilePickerService.pdfExtension],
      );
    } on Exception catch (error) {
      throw FilePickerException('$error');
    }

    final picked = <PickedPdfFile>[];
    for (final file in files) {
      // Same escape-hatch guard as pickPdf: the dialog filters by extension,
      // but Android content providers and "All files" pickers can still
      // hand back something else.
      if (!isPdfFileName(file.name)) {
        throw FilePickerException(
          'Picked file is not a PDF: ${file.name}',
          kind: FilePickerErrorKind.notPdf,
        );
      }
      picked.add(await _toPickedFile(file));
    }
    return picked;
  }

  @override
  Future<PickedPdfFile> resolveDroppedPath(String path) async {
    final name = _fileNameOf(path);
    if (!isPdfFileName(name)) {
      throw FilePickerException(
        'Dropped file is not a PDF: $name',
        kind: FilePickerErrorKind.notPdf,
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      throw FilePickerException(
        'Dropped path is not a readable file: $path',
        kind: FilePickerErrorKind.unreadable,
      );
    }

    try {
      return PickedPdfFile(
        name: name,
        sizeInBytes: await file.length(),
        path: path,
        readBytes: file.readAsBytes,
      );
    } on FileSystemException catch (error) {
      throw FilePickerException(
        '$error',
        kind: FilePickerErrorKind.unreadable,
      );
    }
  }

  @override
  Future<bool> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    Uri? savedUri;
    try {
      savedUri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/pdf',
        allowedExtensions: const [FilePickerService.pdfExtension],
        type: FileType.custom,
      );
    } on Exception catch (error) {
      throw FilePickerException('$error');
    }
    return savedUri != null;
  }

  @override
  Future<bool> saveZip({
    required String fileName,
    required Uint8List bytes,
  }) async {
    Uri? savedUri;
    try {
      savedUri = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/zip',
        allowedExtensions: const ['zip'],
        type: FileType.custom,
      );
    } on Exception catch (error) {
      throw FilePickerException('$error');
    }
    return savedUri != null;
  }

  Future<PickedPdfFile> _toPickedFile(PlatformFile file) async {
    try {
      return PickedPdfFile(
        name: file.name,
        sizeInBytes: await file.length(),
        path: file.path,
        readBytes: file.readAsBytes,
      );
    } on Exception catch (error) {
      throw FilePickerException(
        '$error',
        kind: FilePickerErrorKind.unreadable,
      );
    }
  }

  /// Last segment of [path], handling both POSIX and Windows separators — the
  /// drop channel reports the host platform's own separator.
  String _fileNameOf(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((part) => part.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }
}
