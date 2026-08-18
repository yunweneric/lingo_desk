import 'package:flutter/material.dart';

import 'app_preferences.dart';

/// App-level settings (theme mode, UI language, onboarding completion,
/// local profile, default target locales) as a [ChangeNotifier], so the
/// router can redirect on onboarding completion and the UI rebuilds when
/// the user switches theme/language.
///
/// Values are persisted through [AppPreferences].
class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._preferences)
    : _themeMode = _preferences.themeMode,
      _uiLanguage = _preferences.uiLanguage,
      _onboardingComplete = _preferences.onboardingComplete,
      _profileName = _preferences.profileName,
      _profileEmail = _preferences.profileEmail,
      _defaultTargetLanguages = List.of(_preferences.defaultTargetLanguages);

  final AppPreferences _preferences;

  ThemeMode _themeMode;
  String _uiLanguage;
  bool _onboardingComplete;
  String _profileName;
  String _profileEmail;
  List<String> _defaultTargetLanguages;

  ThemeMode get themeMode => _themeMode;
  String get uiLanguage => _uiLanguage;
  bool get onboardingComplete => _onboardingComplete;
  String get profileName => _profileName;
  String get profileEmail => _profileEmail;
  List<String> get defaultTargetLanguages =>
      List.unmodifiable(_defaultTargetLanguages);

  /// Up to two uppercase initials derived from [profileName], used by the
  /// sidebar footer and the settings avatar. Falls back to the brand mark.
  String get profileInitials {
    final words = _profileName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return 'LD';
    }
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0].substring(0, 1) + words[1].substring(0, 1)).toUpperCase();
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) {
      return;
    }
    _themeMode = mode;
    _preferences.setThemeMode(mode);
    notifyListeners();
  }

  void setUiLanguage(String language) {
    if (language == _uiLanguage) {
      return;
    }
    _uiLanguage = language;
    _preferences.setUiLanguage(language);
    notifyListeners();
  }

  void completeOnboarding() {
    if (_onboardingComplete) {
      return;
    }
    _onboardingComplete = true;
    _preferences.setOnboardingComplete(true);
    notifyListeners();
  }

  void setProfileName(String name) {
    final trimmed = name.trim();
    // An empty name would leave the sidebar footer blank.
    final next = trimmed.isEmpty ? 'Local workspace' : trimmed;
    if (next == _profileName) {
      return;
    }
    _profileName = next;
    _preferences.setProfileName(next);
    notifyListeners();
  }

  void setProfileEmail(String email) {
    final next = email.trim();
    if (next == _profileEmail) {
      return;
    }
    _profileEmail = next;
    _preferences.setProfileEmail(next);
    notifyListeners();
  }

  void setDefaultTargetLanguages(List<String> languages) {
    final next = List.of(languages);
    _defaultTargetLanguages = next;
    _preferences.setDefaultTargetLanguages(next);
    notifyListeners();
  }

  /// Adds or removes [language] from the defaults used by new apps.
  void toggleDefaultTargetLanguage(String language) {
    final next = List.of(_defaultTargetLanguages);
    if (next.contains(language)) {
      next.remove(language);
    } else {
      next.add(language);
    }
    setDefaultTargetLanguages(next);
  }
}
