import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../app_settings/presentation/widgets/language_target_selector.dart';
import '../../../../core/localization/export.dart';

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
          WorkspaceCardHeader(
            title: LocaleKeys.settingsDefaultsTitle.tr(),
            subtitle: LocaleKeys.settingsDefaultsSubtitle.tr(),
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
                ? LocaleKeys.settingsDefaultsEmpty.tr()
                : LocaleKeys.settingsDefaultsCount.plural(selected.length),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
