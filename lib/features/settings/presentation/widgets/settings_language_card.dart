import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../../core/localization/export.dart';

/// Interface language. Persisted and applied to `MaterialApp.locale`.
class SettingsLanguageCard extends StatelessWidget {
  const SettingsLanguageCard({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkspaceCardHeader(
            title: LocaleKeys.settingsInterfaceLanguage.tr(),
            subtitle: LocaleKeys.settingsInterfaceLanguageSubtitle.tr(),
            icon: HugeIcons.strokeRoundedLanguageSquare,
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in AppLocalization.interfaceLanguageOptions)
                ChoiceChip(
                  label: Text(
                    '${option.flag}  ${SupportedLanguages.nameOf(option.code)} '
                    '(${option.code})',
                  ),
                  selected: settings.uiLanguage == option.code,
                  onSelected: (_) {
                    settings.setUiLanguage(option.code);
                    AppLocalization.setLocale(context, option.code);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.settingsInterfaceLanguageNote.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
