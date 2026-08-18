import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/picked_translation_file.dart';

/// Platform file-picking operations for translation imports.
abstract class FileUploadRepository {
  /// Opens the platform picker and returns the selected `.json` files.
  ///
  /// Returns an empty list when the user cancels.
  Future<Either<Failure, List<PickedTranslationFile>>> pickTranslationFiles();
}
