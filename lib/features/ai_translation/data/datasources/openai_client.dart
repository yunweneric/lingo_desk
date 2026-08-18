import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ai_credentials.dart';
import '../../domain/entities/ai_translation_item.dart';
import 'ai_client.dart';
import 'ai_prompt.dart';

/// OpenAI chat completions API.
class OpenAiClient implements AiClient {
  const OpenAiClient(this.httpClient);

  final http.Client httpClient;

  static const _base = 'https://api.openai.com/v1';
  static const _provider = 'OpenAI';

  Map<String, String> _headers(AiCredentials credentials) => {
    'content-type': 'application/json',
    'authorization': 'Bearer ${credentials.apiKey}',
  };

  @override
  Future<Map<String, String>> translate({
    required AiCredentials credentials,
    required String sourceLanguage,
    required String targetLanguage,
    required List<AiTranslationItem> items,
  }) async {
    final response = await httpClient.post(
      Uri.parse('$_base/chat/completions'),
      headers: _headers(credentials),
      body: jsonEncode({
        'model': credentials.model,
        'messages': [
          {
            'role': 'system',
            'content': AiPrompt.systemPrompt(
              sourceLanguage: sourceLanguage,
              targetLanguage: targetLanguage,
            ),
          },
          {'role': 'user', 'content': AiPrompt.userPayload(items)},
        ],
        'response_format': {
          'type': 'json_schema',
          'json_schema': {
            'name': 'translations',
            'strict': true,
            'schema': AiPrompt.responseSchema,
          },
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
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const AiException('OpenAI returned an empty response.');
    }
    final message = (choices.first as Map)['message'];
    final text = message is Map ? message['content'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw const AiException('OpenAI returned an empty response.');
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
}
