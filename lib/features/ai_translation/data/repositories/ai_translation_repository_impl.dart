import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ai_credentials.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/ai_translation_item.dart';
import '../../domain/repositories/ai_translation_repository.dart';
import '../datasources/ai_client.dart';
import '../../../../core/localization/export.dart';

class AiTranslationRepositoryImpl implements AiTranslationRepository {
  const AiTranslationRepositoryImpl({required this.clients});

  /// One client per provider, so switching providers is a map lookup rather
  /// than a second code path through the repository.
  final Map<AiProvider, AiClient> clients;

  /// Retries after the first attempt. Rate limits and 5xx are the common
  /// failures on a long run, and both usually clear within a few seconds.
  static const _maxRetries = 2;

  @override
  Future<Either<Failure, Map<String, String>>> translateBatch({
    required AiCredentials credentials,
    required String sourceLanguage,
    required String targetLanguage,
    required List<AiTranslationItem> items,
  }) {
    return _guard(
      () => _client(credentials).translate(
        credentials: credentials,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        items: items,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> verifyCredentials(AiCredentials credentials) {
    return _guard<Unit>(() async {
      await _client(credentials).verify(credentials);
      return unit;
    });
  }

  AiClient _client(AiCredentials credentials) {
    final client = clients[credentials.provider];
    if (client == null) {
      // Unreachable while every provider is registered; 400 keeps the
      // guard from retrying a configuration mistake.
      throw AiException(
        '${credentials.provider.label} is not supported yet.',
        statusCode: 400,
      );
    }
    return client;
  }

  /// Runs [action], retrying the failures that are worth retrying, and maps
  /// everything that escapes to an [AiFailure].
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    var attempt = 0;
    while (true) {
      try {
        return Right(await action());
      } on AiException catch (e) {
        if (e.isRetryable && attempt < _maxRetries) {
          await Future<void>.delayed(_backoff(attempt));
          attempt++;
          continue;
        }
        return Left(AiFailure(message: e.message));
      } on SocketException {
        if (attempt < _maxRetries) {
          await Future<void>.delayed(_backoff(attempt));
          attempt++;
          continue;
        }
        return Left(
          AiFailure(message: LocaleKeys.errorsAiNoConnection.tr()),
        );
      } on TimeoutException {
        return Left(
          AiFailure(message: LocaleKeys.errorsAiTimeout.tr()),
        );
      } on FormatException {
        return Left(
          AiFailure(
            message: LocaleKeys.errorsAiMalformed.tr(),
          ),
        );
      } on Exception catch (e) {
        return Left(AiFailure(message: e.toString()));
      }
    }
  }

  Duration _backoff(int attempt) =>
      Duration(milliseconds: 800 * (attempt + 1) * (attempt + 1));
}
