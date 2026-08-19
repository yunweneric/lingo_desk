import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/json_flattener.dart';
import '../../../../core/localization/export.dart';

class ParseTranslationFileParams {
  const ParseTranslationFileParams({required this.content});

  final String content;
}

/// Parses a translation file's raw JSON into a flattened
/// `dot.key -> value` map.
class ParseTranslationFile
    implements UseCase<Map<String, String>, ParseTranslationFileParams> {
  ParseTranslationFile();

  @override
  Future<Either<Failure, Map<String, String>>> call(
    ParseTranslationFileParams params,
  ) async {
    try {
      final decoded = jsonDecode(params.content);
      if (decoded is! Map) {
        return Left(
          ValidationFailure(message: LocaleKeys.errorsJsonNotObject.tr()),
        );
      }
      final flat = JsonFlattener.flatten(Map<String, dynamic>.from(decoded));
      if (flat.isEmpty) {
        return Left(
          ValidationFailure(message: LocaleKeys.errorsJsonNoKeys.tr()),
        );
      }
      return Right(flat);
    } on FormatException catch (e) {
      return Left(
        ValidationFailure(
          message: LocaleKeys.errorsJsonInvalid.tr(
            namedArgs: {'error': e.message},
          ),
        ),
      );
    }
  }
}
