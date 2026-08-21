/// The kind of failure a file selection ran into.
///
/// Widgets switch on this to pick the right localized message instead of
/// showing the raw technical reason.
enum FilePickerErrorKind {
  /// The user (or a drag-drop) supplied something that is not a PDF.
  notPdf,

  /// The file exists but cannot be read — missing, moved, or permission denied.
  unreadable,

  /// The platform picker itself failed to open or returned an unusable result.
  pickerFailure,
}

/// Thrown by `FilePickerService` when a file selection cannot be accepted.
///
/// A cancelled dialog is *not* an error — that surfaces as `null` instead.
final class FilePickerException implements Exception {
  const FilePickerException(
    this.message, {
    this.kind = FilePickerErrorKind.pickerFailure,
  });

  /// Technical reason, for logs — never shown to the user directly.
  final String message;

  /// Which branch of failure this is.
  final FilePickerErrorKind kind;

  @override
  String toString() => message;
}
