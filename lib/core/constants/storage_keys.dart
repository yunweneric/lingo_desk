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
  static const uiLanguage = 'lingo_desk_ui_language';
  static const onboardingComplete = 'lingo_desk_onboarding_complete';

  /// Local profile shown in the sidebar footer and the settings page.
  static const profileName = 'lingo_desk_profile_name';
  static const profileEmail = 'lingo_desk_profile_email';

  /// Target locales pre-selected when creating a new app.
  static const defaultTargetLanguages = 'lingo_desk_default_target_languages';
}
