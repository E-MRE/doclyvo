final class JsonException implements Exception {
  const JsonException();

  String get message => 'JSON parsing error';

  @override
  String toString() => message;
}
