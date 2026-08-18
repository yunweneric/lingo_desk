/// Base class for all failures returned by repositories and use cases.
///
/// Failures travel through the domain layer inside `Either<Failure, T>`
/// (from the `dartz` package) instead of thrown exceptions.
abstract class Failure {
  const Failure({required this.message});

  final String message;
}

/// Failure raised when reading from or writing to local storage fails.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Failure raised when user input or imported data is invalid.
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Failure raised when picking, reading, or writing files fails.
class FileFailure extends Failure {
  const FileFailure({required super.message});
}
