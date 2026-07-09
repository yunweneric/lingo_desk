import 'package:flutter/material.dart';

import '../features/app_management/presentation/pages/app_dashboard_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import 'theme/lingo_desk_theme.dart';

/// Root application widget
///
/// This widget is the entry point of the application UI.
/// It configures the MaterialApp with theme, routes, and global settings.
class LingoDeskApp extends StatefulWidget {
  const LingoDeskApp({super.key});

  @override
  State<LingoDeskApp> createState() => _LingoDeskAppState();
}

class _LingoDeskAppState extends State<LingoDeskApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _selectedLanguage = 'en';
  bool _showOnboarding = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoDesk',
      debugShowCheckedModeBanner: false,
      theme: LingoDeskTheme.light(),
      darkTheme: LingoDeskTheme.dark(),
      themeMode: _themeMode,
      locale: Locale(_selectedLanguage),
      home:
          _showOnboarding
              ? OnboardingPage(onComplete: _completeOnboarding)
              : AppDashboardPage(
                themeMode: _themeMode,
                onThemeModeChanged: _setThemeMode,
                selectedLanguage: _selectedLanguage,
                onLanguageChanged: _setLanguage,
              ),
    );
  }

  void _completeOnboarding() {
    setState(() => _showOnboarding = false);
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _setLanguage(String language) {
    setState(() => _selectedLanguage = language);
  }
}
