import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/picked_translation_file.dart';
import '../../domain/repositories/file_upload_repository.dart';
import '../datasources/file_picker_data_source.dart';

class FileUploadRepositoryImpl implements FileUploadRepository {
  const FileUploadRepositoryImpl({required this.filePickerDataSource});

  final FilePickerDataSource filePickerDataSource;

  @override
  Future<Either<Failure, List<PickedTranslationFile>>>
  pickTranslationFiles() async {
    try {
      final files = await filePickerDataSource.pickJsonFiles();
      return Right([
        for (final file in files)
          PickedTranslationFile(fileName: file.fileName, content: file.content),
      ]);
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on Exception catch (e) {
      return Left(FileFailure(message: e.toString()));
    }
  }
}
