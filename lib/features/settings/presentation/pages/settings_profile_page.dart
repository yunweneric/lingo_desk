import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../widgets/settings_profile_card.dart';
import 'settings_pane.dart';

/// Who the workspace belongs to: display name and initials.
class SettingsProfilePage extends StatelessWidget {
  const SettingsProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<AppSettingsController>();

    return SettingsPane(
      title: 'Profile',
      listenable: settings,
      builder: (context) => SettingsProfileCard(settings: settings),
    );
  }
}
