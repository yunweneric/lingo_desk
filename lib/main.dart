import 'package:flutter/material.dart';

import 'core/app.dart';
import 'core/bootstrap.dart';
import 'core/di/injection_container.dart';
import 'core/localization/export.dart';
import 'core/preferences/app_settings_controller.dart';

/// Application entry point
///
/// This function initializes the app using the Bootstrap class
/// and then runs the LingoDeskApp widget.
void main() async {
  // Initialize app services and configuration
  await Bootstrap.initialize();

  // The saved UI language wins over the device locale: it is an explicit
  // choice the user made in settings.
  final settings = getIt<AppSettingsController>();

  // Run the application
  runApp(
    AppLocalization.wrap(
      startLocale: Locale(settings.uiLanguage),
      child: const LingoDeskApp(),
    ),
  );
}
