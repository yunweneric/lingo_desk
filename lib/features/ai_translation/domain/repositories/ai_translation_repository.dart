import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ai_credentials.dart';
import '../entities/ai_translation_item.dart';

/// Machine translation through a third-party model provider.
abstract class AiTranslationRepository {
  /// Translates one batch of entries into [targetLanguage].
  ///
  /// Returns `dot.key -> translated value`, containing only keys that were
  /// asked for and came back with a non-empty value; a model that drops or
  /// invents a key simply yields a shorter map rather than an error.
  Future<Either<Failure, Map<String, String>>> translateBatch({
    required AiCredentials credentials,
    required String sourceLanguage,
    required String targetLanguage,
    required List<AiTranslationItem> items,
  });

  /// Checks the key against the provider's model list. Costs no tokens.
  Future<Either<Failure, void>> verifyCredentials(AiCredentials credentials);
}
