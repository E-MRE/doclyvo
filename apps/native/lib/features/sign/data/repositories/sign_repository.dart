import 'dart:typed_data';

import 'package:doclyvo/features/sign/domain/models/signature_placement.dart';

/// Sign's data layer: places a signature graphic onto one page of a document.
///
/// Fully client-side, like every other Phase 3A tool — there is no network
/// call here at all. In particular this interface deliberately exposes **no**
/// hash or audit-log operation: `apps/web`'s Sign records an append-only audit
/// trail for signed-in users, which needs auth plus Postgres, and native MVP
/// has neither. See the P3A-8 Decisions log entry in `NATIVE-TASKS.md` — that
/// omission is a decision, not an oversight, and adding it later is a visible
/// interface change.
abstract class SignRepository {
  /// Page count of the document at [bytes], read without modifying it —
  /// display metadata for the page selector and the result panel.
  Future<int> readPageCount({required Uint8List bytes});

  /// Stamps [signatureImageBytes] onto page [pageIndex] (zero-based) of
  /// [bytes], inside the box [placement] describes.
  ///
  /// The fraction→points conversion happens here rather than on the screen:
  /// it needs the page's media box, which only the engine can report.
  Future<Uint8List> sign({
    required Uint8List bytes,
    required Uint8List signatureImageBytes,
    required int pageIndex,
    required SignaturePlacement placement,
  });
}
