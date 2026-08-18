import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app.dart';
import '../entities/app_overview.dart';

/// Data operations for localization projects.
abstract class AppRepository {
  Future<Either<Failure, List<App>>> getApps();
  Future<Either<Failure, List<AppOverview>>> getAppOverviews();
  Future<Either<Failure, App>> getAppById(String id);
  Future<Either<Failure, App>> createApp(App app);
  Future<Either<Failure, App>> updateApp(App app);
  Future<Either<Failure, void>> deleteApp(String id);
}
