import 'dart:typed_data';

/// Lazily reads the full contents of a picked file.
typedef PickedFileByteReader = Future<Uint8List> Function();

/// A PDF the user handed to the app, either through the platform file-picker
/// dialog or a desktop drag-drop.
///
/// Deliberately free of any picker-package types: features receive this model,
/// not a `PlatformFile`/`DropItem`, so swapping the picker implementation stays
/// a one-file change (same reasoning as `NetworkService`/`PdfEngineService`).
/// The bytes are read on demand via [readBytes] — nothing is loaded into memory
/// while the file merely sits in a dropzone.
final class PickedPdfFile {
  const PickedPdfFile({
    required this.name,
    required this.sizeInBytes,
    required PickedFileByteReader readBytes,
    this.path,
  }) : _readBytes = readBytes;

  /// File name including the `.pdf` extension, e.g. `rapor-2024.pdf`.
  final String name;

  /// Size of the file on disk, in bytes.
  final int sizeInBytes;

  /// Absolute path on disk, or `null` when the platform only exposes a
  /// content URI (some Android providers).
  final String? path;

  final PickedFileByteReader _readBytes;

  /// Reads the whole document — call this at the feature edge, right before
  /// handing the bytes to `PdfEngineService` or a repository.
  Future<Uint8List> readBytes() => _readBytes();

  /// Byte-size unit symbols. Not localized on purpose: `KB`/`MB` are written
  /// the same way in Turkish, and `apps/web` renders them identically.
  static const List<String> _unitSymbols = ['B', 'KB', 'MB', 'GB'];
  static const int _unitStep = 1024;

  /// Human-readable size for the dropzone's file tile, e.g. `8.6 MB`.
  String get formattedSize {
    var size = sizeInBytes.toDouble();
    var unitIndex = 0;
    while (size >= _unitStep && unitIndex < _unitSymbols.length - 1) {
      size /= _unitStep;
      unitIndex++;
    }

    final fractionDigits = unitIndex == 0 ? 0 : 1;
    return '${size.toStringAsFixed(fractionDigits)} ${_unitSymbols[unitIndex]}';
  }
}
