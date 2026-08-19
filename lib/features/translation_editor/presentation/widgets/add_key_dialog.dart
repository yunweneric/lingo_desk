import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/utils/json_flattener.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/widgets/lingo_desk_dialog.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../../../core/localization/export.dart';

/// The values collected by [AddKeyDialog]: the key plus whatever
/// translations were typed, mapped by language code.
class AddKeyRequest {
  const AddKeyRequest({required this.key, required this.values});

  final String key;
  final Map<String, String> values;
}

/// Dialog to add a translation key with a value per language.
///
/// Validates dot-notation format and uniqueness before submitting.
class AddKeyDialog extends StatefulWidget {
  const AddKeyDialog({
    super.key,
    required this.existingKeys,
    required this.languages,
    required this.sourceLanguage,
  });

  final Set<String> existingKeys;

  /// Every language of the app, source first.
  final List<String> languages;

  final String sourceLanguage;

  /// Shows the dialog and returns the request, or null when canceled.
  static Future<AddKeyRequest?> show(
    BuildContext context, {
    required Set<String> existingKeys,
    required List<String> languages,
    required String sourceLanguage,
  }) {
    return showDialog<AddKeyRequest>(
      context: context,
      builder: (_) => AddKeyDialog(
        existingKeys: existingKeys,
        languages: languages,
        sourceLanguage: sourceLanguage,
      ),
    );
  }

  @override
  State<AddKeyDialog> createState() => _AddKeyDialogState();
}

class _AddKeyDialogState extends State<AddKeyDialog> {
  /// Gutter between the language fields, both axes.
  static const _gap = 16.0;

  final _keyController = TextEditingController();
  late final Map<String, TextEditingController> _valueControllers = {
    for (final language in widget.languages) language: TextEditingController(),
  };
  String? _error;

  @override
  void dispose() {
    _keyController.dispose();
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final key = _keyController.text.trim();
    if (!JsonFlattener.isValidKey(key)) {
      setState(() {
        _error = LocaleKeys.errorsInvalidKey.tr();
      });
      return;
    }
    if (widget.existingKeys.contains(key)) {
      setState(
        () => _error = LocaleKeys.errorsKeyExists.tr(namedArgs: {'key': key}),
      );
      return;
    }

    // Blank fields stay missing rather than being stored as empty text.
    final values = <String, String>{
      for (final entry in _valueControllers.entries)
        if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text,
    };
    Navigator.of(context).pop(AddKeyRequest(key: key, values: values));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final theme = Theme.of(context);

    // Wide enough for full sentences, since every language is edited
    // here rather than only the source — but never wider than the window.
    return LingoDeskDialog(
      title: Text(LocaleKeys.editorAddKey.tr()),
      preferredWidth: 1120,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LingoDeskTextField(
            controller: _keyController,
            label: LocaleKeys.editorKeyLabel.tr(),
            hintText: 'nav.home',
            helperText: LocaleKeys.editorKeyHelper.tr(),
            errorText: _error,
            size: LingoDeskFieldSize.large,
            monospace: true,
            autofocus: true,
            isRequired: true,
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          Text(
            LocaleKeys.editorTranslations.tr(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: tokens.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleKeys.editorAddKeyHint.tr(),
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: ResponsiveBuilder(
                builder: (context, size, constraints) {
                  // Two columns once a field still fits a sentence,
                  // three on a full-width desktop window, one on a phone.
                  final width = constraints.maxWidth;
                  final columns = size.resolve(compact: 1, medium: 2, large: 3);
                  final itemWidth = (width - _gap * (columns - 1)) / columns;

                  return Wrap(
                    spacing: _gap,
                    runSpacing: _gap,
                    children: [
                      for (final language in widget.languages)
                        SizedBox(
                          // The source string carries the most text, so
                          // it keeps a row to itself in a grid.
                          width: language == widget.sourceLanguage
                              ? width
                              : itemWidth,
                          child: LingoDeskTextField(
                            controller: _valueControllers[language],
                            label: _labelFor(language),
                            hintText: language == widget.sourceLanguage
                                ? LocaleKeys.editorSourceText.tr()
                                : LocaleKeys.editorTranslationOptional.tr(),
                            size: LingoDeskFieldSize.large,
                            maxLines: 3,
                            minLines: 1,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.commonCancel.tr()),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(LocaleKeys.editorAddKey.tr()),
        ),
      ],
    );
  }

  String _labelFor(String language) {
    final label =
        '${SupportedLanguages.flagOf(language)}  '
        '${SupportedLanguages.nameOf(language)} ($language)';
    return language == widget.sourceLanguage
        ? LocaleKeys.uploadLanguageSource.tr(namedArgs: {'language': label})
        : label;
  }
}
