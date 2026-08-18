import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/ai_credentials.dart';
import '../../domain/entities/ai_translation_item.dart';
import 'ai_client.dart';
import 'ai_prompt.dart';

/// Anthropic Messages API.
class AnthropicClient implements AiClient {
  const AnthropicClient(this.httpClient);

  final http.Client httpClient;

  static const _base = 'https://api.anthropic.com/v1';
  static const _version = '2023-06-01';
  static const _provider = 'Anthropic';

  Map<String, String> _headers(AiCredentials credentials) => {
    'content-type': 'application/json',
    'x-api-key': credentials.apiKey,
    'anthropic-version': _version,
  };

  @override
  Future<Map<String, String>> translate({
    required AiCredentials credentials,
    required String sourceLanguage,
    required String targetLanguage,
    required List<AiTranslationItem> items,
  }) async {
    final response = await httpClient.post(
      Uri.parse('$_base/messages'),
      headers: _headers(credentials),
      body: jsonEncode({
        'model': credentials.model,
        'max_tokens': 8192,
        'system': AiPrompt.systemPrompt(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        ),
        'messages': [
          {'role': 'user', 'content': AiPrompt.userPayload(items)},
        ],
        // Translation is a shallow task and the schema already pins the
        // output shape, so thinking only adds latency and cost. Disabling it
        // is accepted at effort `high` or below.
        'thinking': {'type': 'disabled'},
        'output_config': {
          'effort': 'low',
          'format': {'type': 'json_schema', 'schema': AiPrompt.responseSchema},
        },
        // No temperature/top_p: current models reject them outright.
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

    // A safety decline is a 200 with an empty or partial content array, so
    // this has to be read before touching content at all.
    if (decoded['stop_reason'] == 'refusal') {
      throw const AiException(
        'Anthropic declined to translate this batch. Skip it or try a '
        'different model.',
      );
    }

    final content = decoded['content'];
    if (content is! List) {
      throw const AiException('Anthropic returned an unexpected response.');
    }
    final text = content
        .whereType<Map>()
        .where((block) => block['type'] == 'text')
        .map((block) => block['text'])
        .whereType<String>()
        .join();
    if (text.trim().isEmpty) {
      throw const AiException('Anthropic returned an empty response.');
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
