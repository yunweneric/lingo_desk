import 'dart:convert';

import '../../../../core/constants/languages.dart';
import '../../domain/entities/ai_translation_item.dart';

/// The prompt, the response schema and the response parser, shared by every
/// provider client.
///
/// All three providers can be asked for schema-constrained JSON, so the only
/// thing that differs between them is where the schema and the text go in the
/// request body — the instructions, the payload and the parsing are identical.
class AiPrompt {
  const AiPrompt._();

  /// Cap on entries per request. Small enough that one failure loses little
  /// work and the response stays well inside any output limit, large enough
  /// that the instructions are amortized across many strings.
  static const batchSize = 25;

  /// JSON Schema every provider is handed.
  ///
  /// Translations come back as an array of key/value pairs rather than an
  /// object keyed by the translation key: the keys vary per request, and an
  /// object schema would need `additionalProperties`, which the strict modes
  /// of these providers reject.
  static Map<String, dynamic> get responseSchema => {
    'type': 'object',
    'additionalProperties': false,
    'required': ['translations'],
    'properties': {
      'translations': {
        'type': 'array',
        'items': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['key', 'value'],
          'properties': {
            'key': {'type': 'string'},
            'value': {'type': 'string'},
          },
        },
      },
    },
  };

  static String systemPrompt({
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final source = _describe(sourceLanguage);
    final target = _describe(targetLanguage);

    return '''
You translate user-interface strings for a software localization tool.

Translate every string from $source into $target.

Rules:
- Return exactly one entry for every key you are given, using the key unchanged.
- Never translate the key itself. Its dot-separated segments describe where the
  string appears in the interface, so use them to disambiguate short or
  ambiguous source text.
- Preserve every placeholder and markup token exactly as written, including
  {name}, {{count}}, %s, %1\$s, :param, \$1 and any HTML tags.
- Keep the capitalization style, punctuation, and any leading or trailing
  whitespace of the source string.
- Keep the translation about as short as the source: these strings sit in
  buttons, labels and menus.
- Leave product names, brand names and code identifiers untranslated.
- Return only the JSON object. No commentary, no code fences.''';
  }

  /// The user turn: the batch as a compact JSON array.
  static String userPayload(List<AiTranslationItem> items) {
    return jsonEncode([
      for (final item in items) {'key': item.key, 'source': item.sourceText},
    ]);
  }

  /// Reads the model's JSON reply into `key -> value`.
  ///
  /// Filters to the keys that were actually requested, so a model that
  /// invents a key or echoes an instruction cannot write a bogus row into the
  /// workspace. Blank values are dropped too — a missing translation should
  /// stay visibly missing rather than become an empty string that reads as
  /// done.
  static Map<String, String> parseResponse(
    String raw,
    List<AiTranslationItem> requested,
  ) {
    final wanted = {for (final item in requested) item.key};
    final decoded = jsonDecode(_stripFences(raw));
    if (decoded is! Map<String, dynamic>) {
      return const {};
    }
    final translations = decoded['translations'];
    if (translations is! List) {
      return const {};
    }

    final result = <String, String>{};
    for (final entry in translations) {
      if (entry is! Map) {
        continue;
      }
      final key = entry['key'];
      final value = entry['value'];
      if (key is String &&
          value is String &&
          wanted.contains(key) &&
          value.trim().isNotEmpty) {
        result[key] = value;
      }
    }
    return result;
  }

  /// Schema-constrained output should never be fenced, but a model asked for
  /// JSON in plain text sometimes wraps it anyway.
  static String _stripFences(String raw) {
    final text = raw.trim();
    if (!text.startsWith('```')) {
      return text;
    }
    final firstBreak = text.indexOf('\n');
    if (firstBreak == -1) {
      return text;
    }
    final withoutOpening = text.substring(firstBreak + 1);
    final closing = withoutOpening.lastIndexOf('```');
    return closing == -1
        ? withoutOpening.trim()
        : withoutOpening.substring(0, closing).trim();
  }

  static String _describe(String code) {
    final name = SupportedLanguages.englishNameOf(code);
    return name == code ? code : '$name ($code)';
  }
}
