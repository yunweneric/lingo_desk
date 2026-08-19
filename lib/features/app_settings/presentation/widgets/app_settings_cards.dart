import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/language_dropdown.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../bloc/app_settings_bloc.dart';
import '../bloc/app_settings_event.dart';
import '../bloc/app_settings_state.dart';
import 'app_icon_field.dart';
import 'language_target_selector.dart';
import '../../../../core/localization/export.dart';

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
          WorkspaceCardHeader(
            title: LocaleKeys.appSettingsGeneral.tr(),
            subtitle: LocaleKeys.appSettingsGeneralSubtitle.tr(),
            icon: HugeIcons.strokeRoundedSettings02,
          ),
          const SizedBox(height: 20),
          AppIconField(state: state, nameController: nameController),
          const SizedBox(height: 22),
          LingoDeskTextField(
            controller: nameController,
            label: LocaleKeys.appSettingsAppName.tr(),
            hintText: LocaleKeys.appSettingsAppNameHint.tr(),
            size: LingoDeskFieldSize.large,
            isRequired: true,
            enabled: !state.isSaving,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitted(),
          ),
          const SizedBox(height: 22),
          LanguageDropdown(
            label: LocaleKeys.appSettingsSourceLanguage.tr(),
            description: LocaleKeys.appSettingsSourceLanguageHelp.tr(),
            value: state.sourceLanguage,
            enabled: !state.isSaving,
            onChanged: (value) => context.read<AppSettingsBloc>().add(
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
    final selectable = SupportedLanguages.all
        .where((option) => option.code != state.sourceLanguage)
        .length;
    final selected = state.targetLanguages.length;

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: WorkspaceCardHeader(
                  title: LocaleKeys.appSettingsTargetLanguages.tr(),
                  subtitle: LocaleKeys.appSettingsTargetLanguagesSubtitle.tr(),
                  icon: HugeIcons.strokeRoundedLanguageSquare,
                ),
              ),
              const SizedBox(width: 12),
              WorkspaceBadge(
                label: LocaleKeys.appSettingsSelectedCount.tr(
                  namedArgs: {
                    'selected': '$selected',
                    'total': '$selectable',
                  },
                ),
                color: selected == 0 ? LingoDeskColors.warning : tokens.accent,
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: state.isSaving || selected == selectable
                    ? null
                    : () => bloc.add(
                        AllTargetLanguagesToggledEvent(selectAll: true),
                      ),
                child: Text(LocaleKeys.appSettingsSelectAll.tr()),
              ),
              TextButton(
                onPressed: state.isSaving || selected == 0
                    ? null
                    : () => bloc.add(
                        AllTargetLanguagesToggledEvent(selectAll: false),
                      ),
                child: Text(LocaleKeys.commonClear.tr()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LanguageTargetGrid(
            sourceLanguage: state.sourceLanguage,
            selectedLanguages: state.targetLanguages,
            onToggled: (language) =>
                bloc.add(TargetLanguageToggledEvent(language)),
          ),
          const SizedBox(height: 14),
          Text(
            LocaleKeys.appSettingsTargetLanguagesNote.tr(),
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
/// source locale, the targets it is translated into and when it last
/// changed.
///
/// One bar rather than a row of little boxes — the facts belong to the
/// same app, and boxed separately they read as three unrelated stats
/// while forcing each value into a fixed width it then has to clip.
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
    final tokens = LingoDeskTokens.of(context);
    final source = state.sourceLanguage;
    final targets = state.targetLanguages;

    final facts = <Widget>[
      _MetaFact(
        icon: HugeIcons.strokeRoundedTranslate,
        label: LocaleKeys.appSettingsMetaSource.tr(),
        value: SupportedLanguages.nameOf(source),
        leading: SupportedLanguages.flagOf(source),
        trailing: source,
      ),
      _MetaFact(
        icon: HugeIcons.strokeRoundedLanguageSquare,
        label: LocaleKeys.appSettingsMetaTargets.tr(),
        value: targets.isEmpty
            ? LocaleKeys.appSettingsMetaNoTargets.tr()
            : LocaleKeys.appSettingsLocaleCount.plural(targets.length),
        // The flags say which locales at a glance; the count already
        // says how many, so a long list folds rather than wraps.
        detail: _FlagRow(languages: targets),
      ),
      _MetaFact(
        icon: HugeIcons.strokeRoundedCalendar03,
        label: LocaleKeys.appSettingsMetaUpdated.tr(),
        value: _formatDate(updatedAt),
        detailText: DateFormatter.relative(updatedAt),
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, size, constraints) {
        // Three facts side by side need a tablet's width; below that they
        // stack.
        final isRow = size.atLeast(WindowSizeClass.medium);

        return Container(
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
            border: Border.all(color: tokens.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: isRow
              // The dividers run the height of the tallest fact and
              // the bar is as tall as that comes to, so the row has
              // to be measured before it can be stretched.
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < facts.length; i++) ...[
                        if (i != 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: tokens.border,
                            ),
                          ),
                        Expanded(child: facts[i]),
                      ],
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < facts.length; index++) ...[
                      if (index != 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: tokens.border,
                          ),
                        ),
                      facts[index],
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// One fact in the strip: an icon, the field name above the value, and an
/// optional aside — the locale code, the flags, the relative time.
class _MetaFact extends StatelessWidget {
  const _MetaFact({
    required this.icon,
    required this.label,
    required this.value,
    this.leading,
    this.trailing,
    this.detail,
    this.detailText,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  /// Emoji shown before [value], for the locale's flag.
  final String? leading;

  /// Monospaced code shown after [value], e.g. `en`.
  final String? trailing;

  final Widget? detail;
  final String? detailText;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final aside = detail;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: LingoDeskIcon(icon, size: 17, color: tokens.muted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  if (leading != null) ...[
                    Text(leading!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      trailing!,
                      style: LingoDeskTheme.codeStyle.copyWith(
                        color: tokens.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (detailText != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '\u00B7 ${detailText!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (aside != null) ...[const SizedBox(height: 6), aside],
            ],
          ),
        ),
      ],
    );
  }
}

/// The selected locales as flags, capped so a long list stays a compact
/// aside rather than a second paragraph.
///
/// A [Wrap] rather than a fitted row: the fact's width is whatever the
/// bar hands it, and wrapping is the one behaviour that cannot overflow
/// it — no measuring of emoji, whose width depends on the font that ends
/// up drawing them.
class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.languages});

  final List<String> languages;

  static const _flagSize = 14.0;
  static const _maxFlags = 8;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    final shown = math.min(languages.length, _maxFlags);
    final hidden = languages.length - shown;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final language in languages.take(shown))
          Tooltip(
            message: SupportedLanguages.nameOf(language),
            child: Text(
              SupportedLanguages.flagOf(language),
              style: const TextStyle(fontSize: _flagSize),
            ),
          ),
        if (hidden > 0)
          Text(
            '+$hidden',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

String _formatDate(DateTime date) => AppLocalization.formatDate(date);
