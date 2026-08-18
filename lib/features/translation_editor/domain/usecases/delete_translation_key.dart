import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/translation_repository.dart';

class DeleteTranslationKeyParams {
  const DeleteTranslationKeyParams({required this.appId, required this.key});

  final String appId;
  final String key;
}

/// Removes a translation key from every language at once.
class DeleteTranslationKey
    implements UseCase<void, DeleteTranslationKeyParams> {
  DeleteTranslationKey(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, void>> call(DeleteTranslationKeyParams params) {
    return repository.deleteKey(params.appId, params.key);
  }
}
