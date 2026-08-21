import 'dart:math';

/// Builds the suggested open-password the Protect screen starts with.
///
/// Mirrors `apps/web`'s generator exactly — 9 characters from a charset that
/// drops the visually ambiguous ones (`0`/`O`, `1`/`l`/`I`) so a password read
/// off the screen and typed elsewhere still opens the document.
final class PasswordGenerator {
  const PasswordGenerator([Random? random]) : _random = random;

  /// Injectable so tests can pin the output; production uses [Random.secure].
  final Random? _random;

  static const String charset =
      r'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$';

  /// How many characters [generate] produces, and the shortest password the
  /// screen accepts — `apps/api` rejects anything under 4, so this is well
  /// clear of the backend rule the web tool shares.
  static const int length = 9;
  static const int minimumLength = 4;

  String generate() {
    final random = _random ?? Random.secure();
    return String.fromCharCodes([
      for (var i = 0; i < length; i++)
        charset.codeUnitAt(random.nextInt(charset.length)),
    ]);
  }
}
