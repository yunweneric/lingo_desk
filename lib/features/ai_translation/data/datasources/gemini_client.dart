import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ai_credentials.dart';
import '../../domain/entities/ai_translation_item.dart';
import 'ai_client.dart';
import 'ai_prompt.dart';

/// Google Gemini generative language API.
class GeminiClient implements AiClient {
  const GeminiClient(this.httpClient);

  final http.Client httpClient;

  static const _base = 'https://generativelanguage.googleapis.com/v1beta';
  static const _provider = 'Gemini';

  Map<String, String> _headers(AiCredentials credentials) => {
    'content-type': 'application/json',
    'x-goog-api-key': credentials.apiKey,
  };

  @override
  Future<Map<String, String>> translate({
    required AiCredentials credentials,
    required String sourceLanguage,
    required String targetLanguage,
    required List<AiTranslationItem> items,
  }) async {
    final response = await httpClient.post(
      Uri.parse('$_base/models/${credentials.model}:generateContent'),
      headers: _headers(credentials),
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {
              'text': AiPrompt.systemPrompt(
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
              ),
            },
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': AiPrompt.userPayload(items)},
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'responseSchema': _geminiSchema(AiPrompt.responseSchema),
        },
      }),
    );

    if (response.statusCode != 200) {
      throw AiErrors.fromResponse(
        provider: _provider,
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    final blockReason = (decoded['promptFeedback'] as Map?)?['blockReason'];
    if (blockReason != null) {
      throw AiException('Gemini blocked this batch ($blockReason).');
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const AiException('Gemini returned an empty response.');
    }
    final candidate = candidates.first as Map;
    final finishReason = candidate['finishReason'];
    if (finishReason != null && finishReason != 'STOP') {
      throw AiException('Gemini stopped early ($finishReason).');
    }

    final parts = (candidate['content'] as Map?)?['parts'];
    final text =
        parts is List
            ? parts
                .whereType<Map>()
                .map((part) => part['text'])
                .whereType<String>()
                .join()
            : '';
    if (text.trim().isEmpty) {
      throw const AiException('Gemini returned an empty response.');
    }

    return AiPrompt.parseResponse(text, items);
  }

  @override
  Future<void> verify(AiCredentials credentials) async {
    final response = await httpClient.get(
      Uri.parse('$_base/models'),
      headers: _headers(credentials),
    );
    if (response.statusCode != 200) {
      throw AiErrors.fromResponse(
        provider: _provider,
        statusCode: response.statusCode,
        body: response.body,
      );
    }
  }

  /// Gemini takes an OpenAPI subset that has no `additionalProperties`, and
  /// rejects the whole request when it sees one — so the shared schema is
  /// stripped of it on the way out.
  static Map<String, dynamic> _geminiSchema(Map<String, dynamic> schema) {
    return {
      for (final entry in schema.entries)
        if (entry.key != 'additionalProperties')
          entry.key: _convertValue(entry.value),
    };
  }

  static dynamic _convertValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _geminiSchema(value);
    }
    if (value is List) {
      return value.map(_convertValue).toList();
    }
    return value;
  }
}
