import 'ai_provider.dart';

/// Everything needed to call one provider: which one, the key, and the model.
class AiCredentials {
  const AiCredentials({
    required this.provider,
    required this.apiKey,
    required this.model,
  });

  final AiProvider provider;
  final String apiKey;
  final String model;

  bool get isConfigured => apiKey.trim().isNotEmpty && model.trim().isNotEmpty;
}
