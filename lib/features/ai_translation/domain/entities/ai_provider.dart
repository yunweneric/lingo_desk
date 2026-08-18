/// A machine-translation provider LingoDesk can call.
///
/// Each provider is one HTTP endpoint with its own auth header and response
/// shape; everything else about a translation run is identical between them.
enum AiProvider { anthropic, openai, gemini }

extension AiProviderInfo on AiProvider {
  /// Name shown on the provider chips in settings.
  String get label => switch (this) {
    AiProvider.anthropic => 'Anthropic',
    AiProvider.openai => 'OpenAI',
    AiProvider.gemini => 'Gemini',
  };

  /// Stable string used as the storage key suffix; never localized.
  String get id => name;

  /// Model used until the user picks another one.
  String get defaultModel => switch (this) {
    AiProvider.anthropic => 'claude-opus-5',
    AiProvider.openai => 'gpt-4o-mini',
    AiProvider.gemini => 'gemini-3.7-flash',
  };

  /// Offered in the model dropdown. The field stays free-text, so a model
  /// released after this list was written can still be typed in.
  List<String> get suggestedModels => switch (this) {
    AiProvider.anthropic => const [
      'claude-opus-5',
      'claude-sonnet-5',
      'claude-haiku-4-5',
    ],
    AiProvider.openai => const ['gpt-4o-mini', 'gpt-4o', 'gpt-4.1-mini'],
    // Google's current stable line. Flash tiers are the right shape for
    // translation — the work is short strings in bulk, not deep reasoning —
    // and Flash-Lite is the cheap option for a large backlog.
    AiProvider.gemini => const [
      'gemini-3.7-flash',
      'gemini-3.6-flash',
      'gemini-3.5-flash-lite',
    ],
  };

  /// Shape of a valid key, shown as the field hint.
  String get keyHint => switch (this) {
    AiProvider.anthropic => 'sk-ant-…',
    AiProvider.openai => 'sk-…',
    AiProvider.gemini => 'AIza…',
  };

  /// Where the user goes to create a key.
  String get consoleLabel => switch (this) {
    AiProvider.anthropic => 'console.anthropic.com',
    AiProvider.openai => 'platform.openai.com',
    AiProvider.gemini => 'aistudio.google.com',
  };

  static AiProvider fromId(String? id) {
    for (final provider in AiProvider.values) {
      if (provider.name == id) {
        return provider;
      }
    }
    return AiProvider.anthropic;
  }
}
