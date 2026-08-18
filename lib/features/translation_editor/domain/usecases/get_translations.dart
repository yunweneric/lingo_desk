import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/translation_entry.dart';
import '../repositories/translation_repository.dart';

class GetTranslationsParams {
  const GetTranslationsParams({required this.appId});

  final String appId;
}

/// Loads all translation entries of an app.
class GetTranslations
    implements UseCase<List<TranslationEntry>, GetTranslationsParams> {
  GetTranslations(this.repository);

  final TranslationRepository repository;

  @override
  Future<Either<Failure, List<TranslationEntry>>> call(
    GetTranslationsParams params,
  ) {
    return repository.getTranslations(params.appId);
  }
}
