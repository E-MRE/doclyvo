import 'dart:typed_data';

import 'package:doclyvo/core/error/file_picker_exception.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_image_file.dart';
import 'package:doclyvo/core/widgets/upload/models/picked_pdf_file.dart';

/// Selecting a PDF from the device, however the platform offers it.
///
/// The only sanctioned way to obtain a file: no feature may import the
/// underlying picker package directly (same rule as `PdfEngineService`), so a
/// future swap touches one file instead of 11 tools. Both entry points funnel
/// through the same PDF-only validation, which is why drag-drop cannot smuggle
/// in a `.docx` that the dialog would have filtered out.
abstract class FilePickerService {
  const FilePickerService();

  /// The single extension every tool accepts as its *document* input.
  static const String pdfExtension = 'pdf';

  /// The only image extension accepted for a signature graphic.
  ///
  /// PNG only, matching `apps/web`'s `accept="image/png"`: a signature needs a
  /// transparent background to sit on top of the page, which JPEG cannot
  /// carry.
  static const String pngExtension = 'png';

  /// Opens the platform's file-picker dialog, filtered to PDFs.
  ///
  /// Returns `null` when the user cancels — that is a normal outcome, not a
  /// failure. Throws [FilePickerException] when the selection is not a readable
  /// PDF, or when the dialog itself fails.
  Future<PickedPdfFile?> pickPdf({String? dialogTitle});

  /// Opens the platform's file-picker dialog, filtered to PDFs, allowing more
  /// than one selection at once.
  ///
  /// Returns an empty list when the user cancels — same "not a failure"
  /// contract as [pickPdf]. Throws [FilePickerException] with
  /// [FilePickerErrorKind.notPdf] if any selected entry is not a readable
  /// PDF, or [FilePickerErrorKind.pickerFailure] when the dialog itself
  /// fails. Added for Merge (P3A-3), the first tool that needs more than one
  /// input file at a time.
  Future<List<PickedPdfFile>> pickMultiplePdfs({String? dialogTitle});

  /// Accepts a file path handed over by a desktop drag-drop.
  ///
  /// Throws [FilePickerException] with [FilePickerErrorKind.notPdf] for
  /// anything that is not a PDF, and [FilePickerErrorKind.unreadable] when the
  /// path does not point at a readable file (e.g. a dropped folder).
  Future<PickedPdfFile> resolveDroppedPath(String path);

  /// Opens the platform's file-picker dialog, filtered to PNG images.
  ///
  /// Returns `null` when the user cancels — same "not a failure" contract as
  /// [pickPdf]. Throws [FilePickerException] with
  /// [FilePickerErrorKind.notPdf] when the selection is not a PNG (the kind
  /// enum names the common case, not the only one), or
  /// [FilePickerErrorKind.pickerFailure] when the dialog itself fails. Added
  /// for Sign (P3A-8), the first tool whose input is not a document.
  Future<PickedImageFile?> pickSignatureImage({String? dialogTitle});

  /// Whether [fileName] carries the `.pdf` extension, case-insensitively.
  bool isPdfFileName(String fileName) =>
      fileName.toLowerCase().endsWith('.$pdfExtension');

  /// Whether [fileName] carries the `.png` extension, case-insensitively.
  bool isPngFileName(String fileName) =>
      fileName.toLowerCase().endsWith('.$pngExtension');

  /// Writes a client-side tool's output [bytes] to disk as [fileName].
  ///
  /// Desktop shows a native file-save dialog; mobile hands the platform its
  /// own save/share flow. Returns `false` when the user cancels — that is a
  /// normal outcome, not a failure.
  Future<bool> savePdf({required String fileName, required Uint8List bytes});

  /// Writes a client-side tool's multi-file output, already zipped into
  /// [bytes], to disk as [fileName].
  ///
  /// Same contract as [savePdf] (native save dialog on desktop, the
  /// platform's save/share flow on mobile, `false` on cancel) — added for
  /// Split (P3A-2), whose result is several PDFs assembled into one archive
  /// rather than a single PDF.
  Future<bool> saveZip({required String fileName, required Uint8List bytes});
}
