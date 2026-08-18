import 'ai_credentials.dart';
import 'ai_provider.dart';

/// One saved API key.
///
/// Keys are a list rather than one slot per provider: the same provider is
/// commonly used with more than one key — a personal key and a work key, or
/// one per client being billed separately — and a per-provider slot forces
/// you to paste over the other one every time you switch.
class AiKey {
  const AiKey({
    required this.id,
    required this.provider,
    required this.label,
    required this.apiKey,
    required this.model,
    required this.createdAt,
  });

  final String id;
  final AiProvider provider;

  /// What the user calls this key. Falls back to the provider name.
  final String label;

  final String apiKey;
  final String model;
  final DateTime createdAt;

  AiCredentials get credentials =>
      AiCredentials(provider: provider, apiKey: apiKey, model: model);

  bool get isUsable => credentials.isConfigured;

  /// Enough of the key to recognise it, never enough to use it.
  ///
  /// Providers put their identifying prefix at the front and randomness at
  /// the back, so keeping both ends is what makes two keys from the same
  /// account tellable apart in a table.
  String get maskedKey {
    final key = apiKey.trim();
    if (key.length <= 12) {
      return '${'•' * key.length.clamp(0, 8)}…';
    }
    return '${key.substring(0, 8)}…${key.substring(key.length - 4)}';
  }

  AiKey copyWith({String? label, String? apiKey, String? model}) {
    return AiKey(
      id: id,
      provider: provider,
      label: label ?? this.label,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      createdAt: createdAt,
    );
  }

  /// Everything except the secret, which lives in the credential store.
  Map<String, dynamic> toMetadataJson() => {
    'id': id,
    'provider': provider.id,
    'label': label,
    'model': model,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Rebuilds an entry from its metadata plus the secret read separately.
  static AiKey fromMetadataJson(Map<String, dynamic> json, String apiKey) {
    return AiKey(
      id: json['id'] as String,
      provider: AiProviderInfo.fromId(json['provider'] as String?),
      label:
          (json['label'] as String?)?.trim().isNotEmpty ?? false
              ? json['label'] as String
              : AiProviderInfo.fromId(json['provider'] as String?).label,
      apiKey: apiKey,
      model: (json['model'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
