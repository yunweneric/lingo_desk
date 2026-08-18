import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/language_dropdown.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import 'language_target_selector.dart';

/// Name + source language, the left column of the app settings page.
class AppSettingsGeneralCard extends StatelessWidget {
  const AppSettingsGeneralCard({
    super.key,
    required this.state,
    required this.nameController,
    required this.onSubmitted,
  });

  final AppSettingsReady state;
  final TextEditingController nameController;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WorkspaceCardHeader(
            title: 'General',
            subtitle: 'How this app is identified and what it translates from.',
            icon: HugeIcons.strokeRoundedSettings02,
          ),
          const SizedBox(height: 20),
          LingoDeskTextField(
            controller: nameController,
            label: 'App name',
            hintText: 'e.g. Customer Portal',
            size: LingoDeskFieldSize.large,
            isRequired: true,
            enabled: !state.isSaving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 22),
          LanguageDropdown(
            label: 'Source language',
            description: 'The base language your keys are written in.',
            value: state.sourceLanguage,
            enabled: !state.isSaving,
            onChanged:
                (value) => context.read<AppSettingsBloc>().add(
                  SourceLanguageChangedEvent(value),
                ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 18),
            LingoDeskFieldError(message: state.errorMessage!),
          ],
        ],
      ),
    );
  }
}

/// The full-width target-language picker, with its selection counter and
/// the select-all / clear shortcuts.
class AppSettingsLanguagesCard extends StatelessWidget {
  const AppSettingsLanguagesCard({super.key, required this.state});

  final AppSettingsReady state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final bloc = context.read<AppSettingsBloc>();
    final selectable =
        SupportedLanguages.all
            .where((option) => option.code != state.sourceLanguage)
            .length;
    final selected = state.targetLanguages.length;

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: WorkspaceCardHeader(
                  title: 'Target languages',
                  subtitle: 'The locales this app is translated into.',
                  icon: HugeIcons.strokeRoundedLanguageSquare,
                ),
              ),
              const SizedBox(width: 12),
              WorkspaceBadge(
                label: '$selected of $selectable selected',
                color:
                    selected == 0
                        ? LingoDeskColors.warning
                        : LingoDeskColors.brandTeal,
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed:
                    state.isSaving || selected == selectable
                        ? null
                        : () => bloc.add(
                          AllTargetLanguagesToggledEvent(selectAll: true),
                        ),
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed:
                    state.isSaving || selected == 0
                        ? null
                        : () => bloc.add(
                          AllTargetLanguagesToggledEvent(selectAll: false),
                        ),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LanguageTargetGrid(
            sourceLanguage: state.sourceLanguage,
            selectedLanguages: state.targetLanguages,
            onToggled:
                (language) => bloc.add(TargetLanguageToggledEvent(language)),
          ),
          const SizedBox(height: 14),
          Text(
            'Every key you add is queued for each selected locale. Removing a '
            'locale hides its column in the editor; the translations you '
            'already have are kept.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// At-a-glance facts about the app, shown under the breadcrumb: the
/// source locale, how many targets are selected and when it last changed.
class AppSettingsMetaStrip extends StatelessWidget {
  const AppSettingsMetaStrip({
    super.key,
    required this.state,
    required this.updatedAt,
  });

  final AppSettingsReady state;
  final DateTime updatedAt;

  @override
  Widget build(BuildContext context) {
    final source = state.sourceLanguage;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        WorkspaceMetaTile(
          label: 'Source',
          value:
              '${SupportedLanguages.flagOf(source)}  '
              '${SupportedLanguages.nameOf(source)}',
          icon: HugeIcons.strokeRoundedTranslate,
          width: 168,
        ),
        WorkspaceMetaTile(
          label: 'Targets',
          value: '${state.targetLanguages.length}',
          icon: HugeIcons.strokeRoundedLanguageSquare,
        ),
        WorkspaceMetaTile(
          label: 'Last updated',
          value: _formatDate(updatedAt),
          icon: HugeIcons.strokeRoundedCalendar03,
          width: 132,
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
