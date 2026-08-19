import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../widgets/settings_appearance_card.dart';
import 'settings_pane.dart';
import '../../../../core/localization/export.dart';

/// Theme mode, and anything else about how the app looks.
class SettingsAppearancePage extends StatelessWidget {
  const SettingsAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<AppSettingsController>();

    return SettingsPane(
      title: LocaleKeys.navAppearance.tr(),
      listenable: settings,
      builder: (context) => SettingsAppearanceCard(settings: settings),
    );
  }
}
