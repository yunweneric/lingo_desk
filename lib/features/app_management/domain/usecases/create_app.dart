import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app.dart';
import '../repositories/app_repository.dart';

class CreateAppParams {
  const CreateAppParams({
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguages,
  });

  final String name;
  final String sourceLanguage;
  final List<String> targetLanguages;
}

/// Creates a new app after validating its configuration.
class CreateApp implements UseCase<App, CreateAppParams> {
  CreateApp(this.repository);

  final AppRepository repository;

  @override
  Future<Either<Failure, App>> call(CreateAppParams params) {
    final validation = validateAppConfig(
      name: params.name,
      sourceLanguage: params.sourceLanguage,
      targetLanguages: params.targetLanguages,
    );
    if (validation != null) {
      return Future.value(Left(ValidationFailure(message: validation)));
    }

    final now = DateTime.now();
    final app = App(
      id: const Uuid().v4(),
      name: params.name.trim(),
      sourceLanguage: params.sourceLanguage,
      targetLanguages: List.unmodifiable(params.targetLanguages),
      createdAt: now,
      updatedAt: now,
    );
    return repository.createApp(app);
  }
}

/// Shared validation for creating/updating an app configuration.
///
/// Returns an error message, or `null` when the configuration is valid.
String? validateAppConfig({
  required String name,
  required String sourceLanguage,
  required List<String> targetLanguages,
}) {
  if (name.trim().isEmpty) {
    return 'App name cannot be empty.';
  }
  if (targetLanguages.isEmpty) {
    return 'Select at least one target language.';
  }
  if (targetLanguages.contains(sourceLanguage)) {
    return 'The source language cannot also be a target language.';
  }
  return null;
}
