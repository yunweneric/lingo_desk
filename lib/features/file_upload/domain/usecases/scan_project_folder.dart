import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/scanned_project_data.dart';
import '../entities/scanned_project.dart';
import '../repositories/file_upload_repository.dart';
import '../translation_grouping.dart';
import 'parse_translation_file.dart';

class ScanProjectFolderParams {
  const ScanProjectFolderParams({this.existing});

  /// Languages already in the preview, so a second folder adds to them
  /// instead of replacing them.
  final List<ScannedLanguageGroup>? existing;
}

/// Picks a project folder, finds its translation files and groups them
/// by language.
///
/// Returns `null` when the user cancels the folder picker. Files that
/// cannot be resolved to a supported language, or that fail to parse,
/// are reported as [SkippedScanFile]s rather than failing the scan.
class ScanProjectFolder
    implements UseCase<ScannedProject?, ScanProjectFolderParams> {
  ScanProjectFolder(this.repository, this.parseTranslationFile);

  final FileUploadRepository repository;
  final ParseTranslationFile parseTranslationFile;

  @override
  Future<Either<Failure, ScannedProject?>> call(
    ScanProjectFolderParams params,
  ) async {
    final scanResult = await repository.scanProject();

    return scanResult.fold<Future<Either<Failure, ScannedProject?>>>(
      (failure) async => Left(failure),
      // A null payload means the folder picker was canceled.
      (data) async =>
          data == null
              ? const Right(null)
              : Right(await _group(data, params.existing)),
    );
  }

  Future<ScannedProject> _group(
    ScannedProjectData data,
    List<ScannedLanguageGroup>? existing,
  ) async {
    final grouper = TranslationGrouper(parseTranslationFile);
    if (existing != null) {
      grouper.seed(existing);
    }

    for (final file in data.files) {
      await grouper.add(
        GroupingCandidate(
          displayPath: file.relativePath,
          fileName: file.fileName,
          parentDirName: file.parentDirName,
          content: file.content,
        ),
      );
    }

    return ScannedProject(
      rootPath: data.rootPath,
      projectName: data.projectName,
      groups: grouper.groups,
      skipped: grouper.skipped,
    );
  }
}
