final class ResponseException implements Exception {
  const ResponseException(this.message);

  final String message;

  @override
  String toString() => message;
}
