import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ai_credentials.dart';
import '../entities/ai_translation_item.dart';
import '../repositories/ai_translation_repository.dart';

class TranslateBatchParams {
  const TranslateBatchParams({
    required this.credentials,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.items,
  });

  final AiCredentials credentials;
  final String sourceLanguage;
  final String targetLanguage;
  final List<AiTranslationItem> items;
}

/// Translates one batch of entries into a single target language.
class TranslateBatch
    implements UseCase<Map<String, String>, TranslateBatchParams> {
  TranslateBatch(this.repository);

  final AiTranslationRepository repository;

  @override
  Future<Either<Failure, Map<String, String>>> call(
    TranslateBatchParams params,
  ) {
    if (params.items.isEmpty) {
      return Future.value(const Right({}));
    }
    if (!params.credentials.isConfigured) {
      return Future.value(
        const Left(
          ValidationFailure(message: 'Add an API key in Settings - AI.'),
        ),
      );
    }
    return repository.translateBatch(
      credentials: params.credentials,
      sourceLanguage: params.sourceLanguage,
      targetLanguage: params.targetLanguage,
      items: params.items,
    );
  }
}
