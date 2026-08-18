import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Thin wrapper around [SharedPreferences] for app-level preferences:
/// theme mode, UI language, and the onboarding-completed flag.
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
}
