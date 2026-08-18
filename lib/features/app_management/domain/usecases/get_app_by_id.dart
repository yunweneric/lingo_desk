import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app.dart';
import '../repositories/app_repository.dart';

class GetAppByIdParams {
  const GetAppByIdParams({required this.id});

  final String id;
}

/// Loads a single app by id.
class GetAppById implements UseCase<App, GetAppByIdParams> {
  GetAppById(this.repository);

  final AppRepository repository;

  @override
  Future<Either<Failure, App>> call(GetAppByIdParams params) {
    return repository.getAppById(params.id);
  }
}
