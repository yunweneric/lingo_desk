import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/json_flattener.dart';
import '../../domain/entities/translation_entry.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/file_export_data_source.dart';
import '../datasources/translation_local_data_source.dart';
import '../models/translation_entry_model.dart';

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
        return Left(CacheFailure(message: 'Key not found: $key'));
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
          ValidationFailure(message: 'The key "$key" already exists.'),
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
        return Left(CacheFailure(message: 'Key not found: $key'));
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
  Future<Either<Failure, int>> exportTranslations(
    String appId,
    List<String> languages,
    String archiveName,
  ) async {
    try {
      final entries = await localDataSource.getEntries(appId);
      if (entries.isEmpty) {
        return const Left(
          ValidationFailure(message: 'There are no keys to export yet.'),
        );
      }

      // Every language goes into one archive, so there is a single save
      // dialog no matter how many are selected.
      final jsonFiles = <String, Map<String, dynamic>>{};
      for (final language in languages) {
        final flat = <String, String>{
          for (final entry in entries.entries)
            entry.key: entry.value[language] ?? '',
        };
        jsonFiles['$language.json'] = JsonFlattener.unflatten(flat);
      }

      final saved = await fileExportDataSource.saveZipFile(
        archiveName,
        jsonFiles,
      );
      return Right(saved ? jsonFiles.length : 0);
    } on FileException catch (e) {
      return Left(FileFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(FileFailure(message: e.toString()));
    }
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
