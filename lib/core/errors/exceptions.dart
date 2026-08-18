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

/// Exception thrown by AI provider clients when a translation request or a
/// credential check fails.
///
/// Repository implementations catch this and convert it to an [AiFailure].
class AiException implements Exception {
  const AiException(this.message, {this.statusCode});

  final String message;

  /// HTTP status returned by the provider, or null for transport failures.
  final int? statusCode;

  /// Whether retrying the same request could plausibly succeed.
  bool get isRetryable =>
      statusCode == null || statusCode == 429 || statusCode! >= 500;

  @override
  String toString() => message;
}
