import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app.dart';
import '../../domain/entities/app_overview.dart';
import '../../domain/repositories/app_repository.dart';
import '../datasources/app_local_data_source.dart';
import '../models/app_model.dart';

class AppRepositoryImpl implements AppRepository {
  const AppRepositoryImpl({required this.localDataSource});

  final AppLocalDataSource localDataSource;

  @override
  Future<Either<Failure, List<App>>> getApps() async {
    try {
      final appsJson = await localDataSource.getApps();
      final apps = appsJson.map(AppModel.fromJson).toList();
      return Right(apps);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AppOverview>>> getAppOverviews() async {
    try {
      final appsJson = await localDataSource.getApps();
      final overviews = <AppOverview>[];
      for (final json in appsJson) {
        final app = AppModel.fromJson(json);
        final blob = await localDataSource.getTranslationBlob(app.id);
        overviews.add(_buildOverview(app, blob));
      }
      overviews.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      return Right(overviews);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, App>> getAppById(String id) async {
    try {
      final json = await localDataSource.getAppById(id);
      if (json == null) {
        return const Left(CacheFailure(message: 'App not found.'));
      }
      return Right(AppModel.fromJson(json));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, App>> createApp(App app) async {
    try {
      final model = AppModel.fromEntity(app);
      await localDataSource.createApp(model.toJson());
      return Right(model);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, App>> updateApp(App app) async {
    try {
      final model = AppModel.fromEntity(app);
      await localDataSource.updateApp(model.toJson());
      return Right(model);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteApp(String id) async {
    try {
      await localDataSource.deleteApp(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  AppOverview _buildOverview(App app, Map<String, dynamic>? blob) {
    final entries = blob == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(blob['entries'] as Map? ?? {});

    final missingByLanguage = <String, int>{
      for (final language in app.targetLanguages) language: 0,
    };

    for (final value in entries.values) {
      final values = Map<String, dynamic>.from(value as Map);
      for (final language in app.targetLanguages) {
        final cell = values[language] as String?;
        if (cell == null || cell.trim().isEmpty) {
          missingByLanguage[language] = missingByLanguage[language]! + 1;
        }
      }
    }

    final missingCount = missingByLanguage.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    var lastActivity = app.updatedAt;
    final lastModifiedRaw = blob?['lastModified'] as String?;
    if (lastModifiedRaw != null) {
      final lastModified = DateTime.tryParse(lastModifiedRaw);
      if (lastModified != null && lastModified.isAfter(lastActivity)) {
        lastActivity = lastModified;
      }
    }

    return AppOverview(
      app: app,
      keyCount: entries.length,
      missingCount: missingCount,
      missingByLanguage: missingByLanguage,
      lastActivity: lastActivity,
    );
  }
}
