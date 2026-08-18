import 'package:flutter/material.dart';

import 'app_preferences.dart';

/// App-level settings (theme mode, UI language, onboarding completion)
/// as a [ChangeNotifier], so the router can redirect on onboarding
/// completion and the UI rebuilds when the user switches theme/language.
///
/// Values are persisted through [AppPreferences].
class AppSettingsController extends ChangeNotifier {
  AppSettingsController(this._preferences)
    : _themeMode = _preferences.themeMode,
      _uiLanguage = _preferences.uiLanguage,
      _onboardingComplete = _preferences.onboardingComplete;

  final AppPreferences _preferences;

  ThemeMode _themeMode;
  String _uiLanguage;
  bool _onboardingComplete;

  ThemeMode get themeMode => _themeMode;
  String get uiLanguage => _uiLanguage;
  bool get onboardingComplete => _onboardingComplete;

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
}
