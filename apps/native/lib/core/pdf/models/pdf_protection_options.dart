/// Settings for the Protect tool.
///
/// The engine supports per-permission flags, not just a password, so the
/// design's no-print / no-copy / no-edit checkboxes map to real restrictions.
final class PdfProtectionOptions {
  const PdfProtectionOptions({
    this.password = '',
    this.ownerPassword,
    this.allowPrinting = true,
    this.allowCopying = true,
    this.allowEditing = true,
  });

  /// Password the reader must type to open the document.
  final String password;

  /// Password that lifts the permission restrictions. Defaults to [password]
  /// when omitted.
  final String? ownerPassword;

  /// Whether printing is permitted.
  final bool allowPrinting;

  /// Whether copying text and images out of the document is permitted.
  final bool allowCopying;

  /// Whether editing — modifying, annotating, filling forms, reassembling —
  /// is permitted.
  final bool allowEditing;
}
