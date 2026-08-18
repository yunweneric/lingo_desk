import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/datasources/scanned_project_data.dart';
import '../entities/picked_translation_file.dart';

/// Platform file-picking operations for translation imports.
abstract class FileUploadRepository {
  /// Opens the platform picker and returns the selected `.json` files.
  ///
  /// Returns an empty list when the user cancels.
  Future<Either<Failure, List<PickedTranslationFile>>> pickTranslationFiles();

  /// Asks for a project folder and returns every `.json` file found in a
  /// translation folder inside it.
  ///
  /// Returns `null` when the user cancels the folder picker.
  Future<Either<Failure, ScannedProjectData?>> scanProject();
}
