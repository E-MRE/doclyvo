/// The kind of failure a client-side PDF operation ran into.
///
/// Mirrors the meaningful branches of the PDF engine's own error hierarchy
/// without exposing the engine package to callers — features switch on this
/// instead of catching third-party exception types.
enum PdfEngineErrorKind {
  /// The document is encrypted and no password was supplied.
  passwordRequired,

  /// A password was supplied but the document rejected it.
  wrongPassword,

  /// The bytes are not a readable PDF.
  corrupted,

  /// A page index was outside the document's page range.
  pageOutOfRange,

  /// The engine cannot perform this operation on this document.
  unsupported,

  /// The operation was cancelled before it finished.
  cancelled,

  /// Anything else — I/O failure, engine crash, invalid argument.
  engineFailure,
}

/// Thrown by `PdfEngineService` when a client-side PDF operation fails.
///
/// Caught by `BaseCubit.safeCall`, which turns it into an error state using
/// [message].
final class PdfEngineException implements Exception {
  const PdfEngineException(
    this.message, {
    this.kind = PdfEngineErrorKind.engineFailure,
  });

  /// Human-readable reason, taken from the engine's own error message.
  final String message;

  /// Which branch of failure this is, for features that react to a specific
  /// case (e.g. re-prompting for a password).
  final PdfEngineErrorKind kind;

  @override
  String toString() => message;
}
