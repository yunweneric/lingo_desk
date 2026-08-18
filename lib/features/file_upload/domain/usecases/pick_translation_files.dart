import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/picked_translation_file.dart';
import '../repositories/file_upload_repository.dart';

/// Opens the platform picker for `.json` translation files.
class PickTranslationFiles
    implements UseCase<List<PickedTranslationFile>, NoParams> {
  PickTranslationFiles(this.repository);

  final FileUploadRepository repository;

  @override
  Future<Either<Failure, List<PickedTranslationFile>>> call(NoParams params) {
    return repository.pickTranslationFiles();
  }
}
