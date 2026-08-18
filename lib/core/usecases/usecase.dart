import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

/// Base contract for all use cases.
///
/// [Type] is the success value produced by the use case and [Params] the
/// input it needs. Use [NoParams] when a use case takes no input.
// The `Type` parameter name follows the project's feature guide.
// ignore: avoid_types_as_parameter_names
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Placeholder params for use cases that take no input.
class NoParams {
  const NoParams();
}
