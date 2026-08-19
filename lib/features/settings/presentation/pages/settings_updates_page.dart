import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/updates/export.dart';
import '../widgets/settings_updates_card.dart';
import 'settings_pane.dart';
import '../../../../core/localization/export.dart';

/// Whether a newer LingoDesk has been published on GitHub.
///
/// The check fires when the pane opens and is remembered for the rest of
/// the run, so moving between panes does not spend GitHub's
/// unauthenticated request budget on a question already answered.
class SettingsUpdatesPage extends StatefulWidget {
  const SettingsUpdatesPage({super.key});

  @override
  State<SettingsUpdatesPage> createState() => _SettingsUpdatesPageState();
}

class _SettingsUpdatesPageState extends State<SettingsUpdatesPage> {
  final UpdateController _controller = getIt<UpdateController>();

  @override
  void initState() {
    super.initState();
    _controller.checkIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPane(
      title: LocaleKeys.navUpdates.tr(),
      listenable: _controller,
      builder: (context) => SettingsUpdatesCard(controller: _controller),
    );
  }
}
