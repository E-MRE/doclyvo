import 'dart:typed_data';

/// Reads the whole image lazily, so picking stays cheap until the feature
/// actually needs the bytes.
typedef PickedImageByteReader = Future<Uint8List> Function();

/// One image chosen through `FilePickerService.pickSignatureImage`.
///
/// Deliberately separate from `PickedPdfFile`: that model's whole contract is
/// "a validated PDF", and the dropzone/result widgets key off it. Sign (P3A-8)
/// is the first tool that needs a *non*-PDF input, and widening
/// `PickedPdfFile` to mean "some file" would silently weaken that guarantee
/// for the other ten tools.
final class PickedImageFile {
  const PickedImageFile({
    required this.name,
    required this.sizeInBytes,
    required PickedImageByteReader readBytes,
    this.path,
  }) : _readBytes = readBytes;

  /// File name including the extension, e.g. `imza.png`.
  final String name;

  /// Size of the file on disk, in bytes.
  final int sizeInBytes;

  /// Absolute path on disk, or `null` when the platform only exposes a
  /// content URI (some Android providers).
  final String? path;

  final PickedImageByteReader _readBytes;

  /// Reads the whole image — call this at the feature edge.
  Future<Uint8List> readBytes() => _readBytes();
}
