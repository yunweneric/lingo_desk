/// SharedPreferences keys shared across features.
///
/// Both `app_management` (for dashboard stats) and `translation_editor`
/// (for the workspace) read the per-app translation blob, so the key
/// builders live in core.
class StorageKeys {
  const StorageKeys._();

  /// JSON array of app metadata objects.
  static const apps = 'lingo_desk_apps';

  /// JSON blob with the translation entries of a single app.
  static String translations(String appId) => 'lingo_desk_translations_$appId';

  /// App-level preferences.
  static const themeMode = 'lingo_desk_theme_mode';

  /// Id of the chosen palette (see `LingoDeskThemeVariant.id`).
  static const themeVariant = 'lingo_desk_theme_variant';
  static const uiLanguage = 'lingo_desk_ui_language';
  static const onboardingComplete = 'lingo_desk_onboarding_complete';

  /// Local profile shown in the sidebar footer and the settings page.
  static const profileName = 'lingo_desk_profile_name';
  static const profileEmail = 'lingo_desk_profile_email';

  /// Target locales pre-selected when creating a new app.
  static const defaultTargetLanguages = 'lingo_desk_default_target_languages';

  /// AI translation keys. The metadata list (id, provider, label, model) is
  /// a plain preference; each secret lives in the platform keychain under
  /// [aiApiKey], addressed by the entry's id.
  static const aiKeys = 'lingo_desk_ai_keys';
  static const aiActiveKeyId = 'lingo_desk_ai_active_key_id';

  /// Secure-storage key holding one entry's API key.
  static String aiApiKey(String id) => 'lingo_desk_ai_api_key_$id';

  /// Pre-list layout: one key per provider, no metadata. Read once so a key
  /// saved by an earlier build is carried into the list instead of lost.
  static const legacyAiProvider = 'lingo_desk_ai_provider';

  static String legacyAiModel(String provider) =>
      'lingo_desk_ai_model_$provider';
}
