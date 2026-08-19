import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/json_flattener.dart';
import '../../domain/entities/export_outcome.dart';
import '../../domain/entities/translation_entry.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/file_export_data_source.dart';
import '../datasources/translation_local_data_source.dart';
import '../models/translation_entry_model.dart';
import '../../../../core/localization/export.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  const TranslationRepositoryImpl({
    required this.localDataSource,
    required this.fileExportDataSource,
  });

  final TranslationLocalDataSource localDataSource;
  final FileExportDataSource fileExportDataSource;

  @override
  Future<Either<Failure, List<TranslationEntry>>> getTranslations(
    String appId,
  ) async {
    try {
      final entries = await localDataSource.getEntries(appId);
      return Right(_toSortedList(entries));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TranslationEntry>>> importTranslations(
    String appId,
    Map<String, Map<String, String>> filesByLanguage,
  ) async {
    try {
      final entries = await localDataSource.getEntries(appId);

      filesByLanguage.forEach((language, flat) {
        flat.forEach((key, value) {
          final values = entries.putIfAbsent(key, () => {});
          values[language] = value;
        });
      });

      await localDataSource.saveEntries(appId, entries);
      return Right(_toSortedList(entries));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateTranslation(
    String appId,
    String key,
    String language,
    String value,
  ) async {
    try {
      final entries = await localDataSource.getEntries(appId);
      final values = entries[key];
      if (values == null) {
        return Left(
          CacheFailure(
            message: LocaleKeys.errorsKeyNotFound.tr(namedArgs: {'key': key}),
          ),
        );
      }
      values[language] = value;
      await localDataSource.saveEntries(appId, entries);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addKey(
    String appId,
    String key,
    Map<String, String> values,
  ) async {
    try {
      final entries = await localDataSource.getEntries(appId);
      if (entries.containsKey(key)) {
        return Left(
          ValidationFailure(
            message: LocaleKeys.errorsKeyExists.tr(namedArgs: {'key': key}),
          ),
        );
      }
      // Blank values are dropped so the key reads as missing for them.
      entries[key] = {
        for (final value in values.entries)
          if (value.value.trim().isNotEmpty) value.key: value.value,
      };
      await localDataSource.saveEntries(appId, entries);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteKey(String appId, String key) async {
    try {
      final entries = await localDataSource.getEntries(appId);
      if (entries.remove(key) == null) {
        return Left(
          CacheFailure(
            message: LocaleKeys.errorsKeyNotFound.tr(namedArgs: {'key': key}),
          ),
        );
      }
      await localDataSource.saveEntries(appId, entries);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExportOutcome>> exportZipToDownloads(
    String appId,
    List<String> languages,
    String archiveName,
  ) async {
    return _export(appId, languages, (entries) async {
      // Every language goes into one archive, so a download is a single
      // file no matter how many languages were selected.
      final jsonFiles = _jsonFilesFor(entries, languages, const {});
      final path = await fileExportDataSource.saveZipToDownloads(
        archiveName,
        jsonFiles,
      );
      return ExportOutcome(location: path, paths: [path]);
    });
  }

  @override
  Future<Either<Failure, ExportOutcome>> exportToFolder(
    String appId,
    List<String> languages,
    String rootPath,
    Map<String, String> languageFiles,
  ) async {
    return _export(appId, languages, (entries) async {
      final jsonFiles = _jsonFilesFor(entries, languages, languageFiles);
      final written = await fileExportDataSource.writeJsonFiles(
        rootPath,
        jsonFiles,
      );
      return ExportOutcome(location: rootPath, paths: written);
    });
  }

  @override
  Future<Either<Failure, String?>> pickExportFolder({
    String? initialDirectory,
  }) async {
    try {
      return Right(
        await fileExportDataSource.pickDestinationFolder(
          initialDirectory: initialDirectory,
        ),
      );
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on Exception catch (e) {
      return Left(FileFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revealExportLocation(String path) async {
    try {
      await fileExportDataSource.revealLocation(path);
      return const Right(null);
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on Exception catch (e) {
      return Left(FileFailure(message: e.toString()));
    }
  }

  /// Loads the app's entries, guards the empty case, and runs [write],
  /// mapping the shared set of storage and file failures.
  Future<Either<Failure, ExportOutcome>> _export(
    String appId,
    List<String> languages,
    Future<ExportOutcome> Function(Map<String, Map<String, String>> entries)
    write,
  ) async {
    try {
      final entries = await localDataSource.getEntries(appId);
      if (entries.isEmpty) {
        return Left(
          ValidationFailure(message: LocaleKeys.errorsNothingToExport.tr()),
        );
      }
      return Right(await write(entries));
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(FileFailure(message: e.toString()));
    }
  }

  /// One nested JSON document per language, keyed by the path it is
  /// written to.
  ///
  /// A language missing from [languageFiles] lands at `<lang>.json`, so
  /// a plain folder export and a language added after the import both
  /// get the obvious name.
  Map<String, Map<String, dynamic>> _jsonFilesFor(
    Map<String, Map<String, String>> entries,
    List<String> languages,
    Map<String, String> languageFiles,
  ) {
    final jsonFiles = <String, Map<String, dynamic>>{};
    for (final language in languages) {
      final flat = <String, String>{
        for (final entry in entries.entries)
          entry.key: entry.value[language] ?? '',
      };
      final path = languageFiles[language] ?? '$language.json';
      jsonFiles[path] = JsonFlattener.unflatten(flat);
    }
    return jsonFiles;
  }

  List<TranslationEntry> _toSortedList(
    Map<String, Map<String, String>> entries,
  ) {
    final list = [
      for (final entry in entries.entries)
        TranslationEntryModel(key: entry.key, values: entry.value),
    ]..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }
}
