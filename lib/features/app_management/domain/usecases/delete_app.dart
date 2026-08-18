import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/app_repository.dart';

class DeleteAppParams {
  const DeleteAppParams({required this.appId});

  final String appId;
}

/// Deletes an app and its stored translations.
class DeleteApp implements UseCase<void, DeleteAppParams> {
  DeleteApp(this.repository);

  final AppRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteAppParams params) {
    return repository.deleteApp(params.appId);
  }
}
