import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../app_settings/presentation/widgets/language_target_selector.dart';

/// Target locales pre-selected in the "New app" dialog.
class SettingsDefaultsCard extends StatelessWidget {
  const SettingsDefaultsCard({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final selected = settings.defaultTargetLanguages;

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceCardHeader(
            title: 'Default target languages',
            subtitle: 'Pre-selected whenever you create a new app.',
            icon: HugeIcons.strokeRoundedGlobe02,
          ),
          const SizedBox(height: 22),
          LanguageTargetSelector(
            sourceLanguage: settings.uiLanguage,
            selectedLanguages: selected,
            onToggled: settings.toggleDefaultTargetLanguage,
          ),
          const SizedBox(height: 16),
          Text(
            selected.isEmpty
                ? 'No defaults yet — new apps start with an empty target list.'
                : '${selected.length} locale'
                      '${selected.length == 1 ? '' : 's'} will be pre-selected.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
