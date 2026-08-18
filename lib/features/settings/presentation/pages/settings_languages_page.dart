import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../widgets/settings_defaults_card.dart';
import '../widgets/settings_language_card.dart';
import 'settings_pane.dart';

/// The two language preferences that are not per-app: the interface
/// locale, and the targets pre-selected for every app you create.
class SettingsLanguagesPage extends StatelessWidget {
  const SettingsLanguagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<AppSettingsController>();

    return SettingsPane(
      title: 'Languages',
      listenable: settings,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsLanguageCard(settings: settings),
          const SizedBox(height: 16),
          SettingsDefaultsCard(settings: settings),
        ],
      ),
    );
  }
}
