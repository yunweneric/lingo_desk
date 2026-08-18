import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ai_credentials.dart';
import '../repositories/ai_translation_repository.dart';

class VerifyAiCredentialsParams {
  const VerifyAiCredentialsParams({required this.credentials});

  final AiCredentials credentials;
}

/// Confirms a key works before the user starts a translation run.
class VerifyAiCredentials implements UseCase<void, VerifyAiCredentialsParams> {
  VerifyAiCredentials(this.repository);

  final AiTranslationRepository repository;

  @override
  Future<Either<Failure, void>> call(VerifyAiCredentialsParams params) {
    if (!params.credentials.isConfigured) {
      return Future.value(
        const Left(ValidationFailure(message: 'Enter an API key first.')),
      );
    }
    return repository.verifyCredentials(params.credentials);
  }
}
