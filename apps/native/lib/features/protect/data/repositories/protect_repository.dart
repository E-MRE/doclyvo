import 'dart:typed_data';

import 'package:doclyvo/core/pdf/models/pdf_protection_options.dart';

/// Encrypts a PDF with an open password and permission flags.
///
/// Sits between the cubit and `PdfEngineService` so the cubit never touches
/// the engine directly (same reasoning as `WatermarkRepository`) — this is
/// Phase 3A, so the concrete implementation calls `PdfEngineService`, never
/// `NetworkService`.
///
/// Deliberately protect-only: the engine also exposes `removeProtection`, but
/// unlocking is not part of this tool (see the P3A-7 Decisions log entry).
abstract class ProtectRepository {
  /// Page count of the document at [bytes], read without modifying it —
  /// display metadata for the result panel.
  Future<int> readPageCount({required Uint8List bytes});

  /// Encrypts [bytes] per [options].
  Future<Uint8List> protect({
    required Uint8List bytes,
    required PdfProtectionOptions options,
  });
}
