/// Exception thrown by data sources when local storage operations fail.
///
/// Repository implementations catch this and convert it to a [CacheFailure].
class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exception thrown by data sources when file operations fail.
class FileException implements Exception {
  const FileException(this.message);

  final String message;

  @override
  String toString() => message;
}
