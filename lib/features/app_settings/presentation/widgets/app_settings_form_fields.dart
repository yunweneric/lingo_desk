import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import 'language_target_selector.dart';

/// The app-configuration form fields (name, source language, target
/// languages, inline validation error), shared by the create dialog and
/// the edit page. Must be built under an [AppSettingsBloc] provider.
class AppSettingsFormFields extends StatelessWidget {
  const AppSettingsFormFields({
    super.key,
    required this.state,
    required this.nameController,
    this.autofocusName = false,
    this.onSubmitted,
  });

  final AppSettingsReady state;
  final TextEditingController nameController;
  final bool autofocusName;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('App name', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          autofocus: autofocusName,
          decoration: const InputDecoration(
            hintText: 'e.g. Customer Portal',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSubmitted?.call(),
        ),
        const SizedBox(height: 24),
        Text('Source language', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          'The base language your keys are written in.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: state.sourceLanguage,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final option in SupportedLanguages.all)
              DropdownMenuItem(
                value: option.code,
                child: Text('${option.flag}  ${option.name} (${option.code})'),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<AppSettingsBloc>().add(
                SourceLanguageChangedEvent(value),
              );
            }
          },
        ),
        const SizedBox(height: 24),
        Text('Target languages', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Text(
          'Languages you want to translate into.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        LanguageTargetSelector(
          sourceLanguage: state.sourceLanguage,
          selectedLanguages: state.targetLanguages,
          onToggled:
              (language) => context.read<AppSettingsBloc>().add(
                TargetLanguageToggledEvent(language),
              ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const LingoDeskIcon(
                HugeIcons.strokeRoundedAlertCircle,
                size: 18,
                color: LingoDeskColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LingoDeskColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
