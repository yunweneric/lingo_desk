import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app_overview.dart';
import '../repositories/app_repository.dart';

/// Loads all apps with their translation stats for the dashboard.
class GetAppOverviews implements UseCase<List<AppOverview>, NoParams> {
  GetAppOverviews(this.repository);

  final AppRepository repository;

  @override
  Future<Either<Failure, List<AppOverview>>> call(NoParams params) {
    return repository.getAppOverviews();
  }
}
