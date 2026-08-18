import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app.dart';
import '../repositories/app_repository.dart';
import 'create_app.dart' show validateAppConfig;

class UpdateAppParams {
  const UpdateAppParams({required this.app});

  final App app;
}

/// Persists changes to an app's configuration, refreshing `updatedAt`.
class UpdateApp implements UseCase<App, UpdateAppParams> {
  UpdateApp(this.repository);

  final AppRepository repository;

  @override
  Future<Either<Failure, App>> call(UpdateAppParams params) {
    final app = params.app;
    final validation = validateAppConfig(
      name: app.name,
      sourceLanguage: app.sourceLanguage,
      targetLanguages: app.targetLanguages,
    );
    if (validation != null) {
      return Future.value(Left(ValidationFailure(message: validation)));
    }

    final updated = App(
      id: app.id,
      name: app.name.trim(),
      sourceLanguage: app.sourceLanguage,
      targetLanguages: List.unmodifiable(app.targetLanguages),
      createdAt: app.createdAt,
      updatedAt: DateTime.now(),
      iconImage: app.iconImage,
      projectPath: app.projectPath,
      languageFiles: Map.unmodifiable(app.languageFiles),
    );
    return repository.updateApp(updated);
  }
}
