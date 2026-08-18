import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/json_flattener.dart';
import '../repositories/translation_repository.dart';

class AddTranslationKeyParams {
  const AddTranslationKeyParams({
    required this.appId,
    required this.key,
    this.values = const {},
  });

  final String appId;
  final String key;

  /// Initial values by language code; languages left out stay missing.
  final Map<String, String> values;
}

/// Adds a new translation key across all languages.
class AddTranslationKey implements UseCase<void, AddTranslationKeyParams> {
  AddTranslationKey(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, void>> call(AddTranslationKeyParams params) {
    final key = params.key.trim();
    if (!JsonFlattener.isValidKey(key)) {
      return Future.value(
        const Left(
          ValidationFailure(
            message:
                'Keys must use dot notation with letters, digits, "_" or "-" '
                '(e.g. nav.home).',
          ),
        ),
      );
    }
    return repository.addKey(params.appId, key, params.values);
  }
}
