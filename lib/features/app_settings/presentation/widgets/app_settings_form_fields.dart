import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/language_dropdown.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import 'app_icon_field.dart';
import 'language_target_selector.dart';
import '../../../../core/localization/export.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconField(state: state, nameController: nameController, size: 56),
        const SizedBox(height: 22),
        LingoDeskTextField(
          controller: nameController,
          label: LocaleKeys.appSettingsAppName.tr(),
          hintText: LocaleKeys.appSettingsAppNameHint.tr(),
          size: LingoDeskFieldSize.large,
          autofocus: autofocusName,
          isRequired: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmitted?.call(),
        ),
        const SizedBox(height: 24),
        LanguageDropdown(
          label: LocaleKeys.appSettingsSourceLanguage.tr(),
          description: LocaleKeys.appSettingsSourceLanguageHelp.tr(),
          value: state.sourceLanguage,
          onChanged: (value) => context.read<AppSettingsBloc>().add(
            SourceLanguageChangedEvent(value),
          ),
        ),
        const SizedBox(height: 24),
        LingoDeskFieldScaffold(
          label: LocaleKeys.appSettingsTargetLanguages.tr(),
          description: LocaleKeys.appSettingsTargetLanguagesHelp.tr(),
          child: LanguageTargetSelector(
            sourceLanguage: state.sourceLanguage,
            selectedLanguages: state.targetLanguages,
            onToggled: (language) => context.read<AppSettingsBloc>().add(
              TargetLanguageToggledEvent(language),
            ),
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 14),
          LingoDeskFieldError(message: state.errorMessage!),
        ],
      ],
    );
  }
}
