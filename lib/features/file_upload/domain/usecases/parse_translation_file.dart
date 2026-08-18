import 'dart:convert';

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/json_flattener.dart';

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
        return const Left(
          ValidationFailure(
            message: 'The file must contain a JSON object at the top level.',
          ),
        );
      }
      final flat = JsonFlattener.flatten(Map<String, dynamic>.from(decoded));
      if (flat.isEmpty) {
        return const Left(
          ValidationFailure(message: 'The file contains no translation keys.'),
        );
      }
      return Right(flat);
    } on FormatException catch (e) {
      return Left(ValidationFailure(message: 'Invalid JSON: ${e.message}'));
    }
  }
}
