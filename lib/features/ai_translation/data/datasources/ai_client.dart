import 'dart:convert';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ai_credentials.dart';
import '../../domain/entities/ai_translation_item.dart';
import '../../../../core/localization/export.dart';

/// One provider's HTTP surface.
///
/// Implementations throw [AiException] on any non-success response so the
/// repository has a single failure type to map, regardless of how differently
/// the providers shape their error bodies.
abstract class AiClient {
  Future<Map<String, String>> translate({
    required AiCredentials credentials,
    required String sourceLanguage,
    required String targetLanguage,
    required List<AiTranslationItem> items,
  });

  /// Lists the provider's models purely to prove the key is accepted.
  Future<void> verify(AiCredentials credentials);
}

/// Turns a provider's error response into one [AiException].
///
/// Every provider nests its message somewhere under an `error` object but
/// disagrees on the exact shape, so the status code carries the meaning and
/// the body only refines the wording.
class AiErrors {
  const AiErrors._();

  static AiException fromResponse({
    required String provider,
    required int statusCode,
    required String body,
  }) {
    final detail = _messageFrom(body);

    final summary = switch (statusCode) {
      401 || 403 =>
        LocaleKeys.errorsAiKeyRejected.tr(namedArgs: {'provider': provider}),
      404 =>
        LocaleKeys.errorsAiModelNotFound.tr(
          namedArgs: {'provider': provider},
        ),
      429 => '$provider rate limit reached. Try again in a moment.',
      >= 500 => '$provider is unavailable right now.',
      _ => '$provider rejected the request.',
    };

    return AiException(
      detail == null ? summary : '$summary ($detail)',
      statusCode: statusCode,
    );
  }

  static String? _messageFrom(String body) {
    if (body.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is Map && error['message'] is String) {
          return error['message'] as String;
        }
        if (error is String) {
          return error;
        }
        if (decoded['message'] is String) {
          return decoded['message'] as String;
        }
      }
    } on FormatException {
      // Not JSON; the status code alone has to carry the message.
    }
    return null;
  }
}
