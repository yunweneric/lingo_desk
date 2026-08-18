import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Thin wrapper around [SharedPreferences] for app-level preferences:
/// theme mode, UI language, the onboarding-completed flag, the local
/// profile, the default target locales for new apps, and the non-secret
/// half of the AI settings (the keys themselves live in [AiCredentialStore]).
class AppPreferences {
  const AppPreferences(this._preferences);

  final SharedPreferences _preferences;

  ThemeMode get themeMode {
    final value = _preferences.getString(StorageKeys.themeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _preferences.setString(StorageKeys.themeMode, mode.name);
  }

  String get uiLanguage =>
      _preferences.getString(StorageKeys.uiLanguage) ?? 'en';

  Future<void> setUiLanguage(String language) {
    return _preferences.setString(StorageKeys.uiLanguage, language);
  }

  bool get onboardingComplete =>
      _preferences.getBool(StorageKeys.onboardingComplete) ?? false;

  Future<void> setOnboardingComplete(bool complete) {
    return _preferences.setBool(StorageKeys.onboardingComplete, complete);
  }

  String get profileName =>
      _preferences.getString(StorageKeys.profileName) ?? 'Local workspace';

  Future<void> setProfileName(String name) {
    return _preferences.setString(StorageKeys.profileName, name);
  }

  String get profileEmail =>
      _preferences.getString(StorageKeys.profileEmail) ?? '';

  Future<void> setProfileEmail(String email) {
    return _preferences.setString(StorageKeys.profileEmail, email);
  }

  List<String> get defaultTargetLanguages =>
      _preferences.getStringList(StorageKeys.defaultTargetLanguages) ??
      const [];

  Future<void> setDefaultTargetLanguages(List<String> languages) {
    return _preferences.setStringList(
      StorageKeys.defaultTargetLanguages,
      languages,
    );
  }

  /// Metadata for every saved AI key, one JSON object per entry. The
  /// secrets are not here — see `AiCredentialStore`.
  List<String> get aiKeys =>
      _preferences.getStringList(StorageKeys.aiKeys) ?? const [];

  Future<void> setAiKeys(List<String> entries) {
    return _preferences.setStringList(StorageKeys.aiKeys, entries);
  }

  /// Id of the key translation runs use, or null when none is chosen.
  String? get aiActiveKeyId =>
      _preferences.getString(StorageKeys.aiActiveKeyId);

  Future<void> setAiActiveKeyId(String? id) {
    return id == null
        ? _preferences.remove(StorageKeys.aiActiveKeyId)
        : _preferences.setString(StorageKeys.aiActiveKeyId, id);
  }

  /// Pre-list provider selection, read only while migrating.
  String? get legacyAiProvider =>
      _preferences.getString(StorageKeys.legacyAiProvider);

  String? legacyAiModel(String provider) =>
      _preferences.getString(StorageKeys.legacyAiModel(provider));

  Future<void> clearLegacyAiSettings(List<String> providerIds) async {
    await _preferences.remove(StorageKeys.legacyAiProvider);
    for (final id in providerIds) {
      await _preferences.remove(StorageKeys.legacyAiModel(id));
    }
  }
}
