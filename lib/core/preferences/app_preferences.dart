import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Thin wrapper around [SharedPreferences] for app-level preferences:
/// theme mode, UI language, the onboarding-completed flag, the local
/// profile, and the default target locales for new apps.
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
}
