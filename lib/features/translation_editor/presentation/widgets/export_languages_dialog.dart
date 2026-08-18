import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_checkbox.dart';
import '../../../../core/widgets/lingo_desk_dialog.dart';

/// Dialog to choose which languages an export covers.
///
/// Shared by all three destinations. The copy and the file name shown
/// against each language are passed in, so the ZIP download, the save
/// back to the project and the folder export each name exactly what they
/// are about to write — which matters most for the project save, where
/// the listed files are overwritten in place.
///
/// Returns the selected language codes, or null when canceled.
class ExportLanguagesDialog extends StatefulWidget {
  const ExportLanguagesDialog({
    super.key,
    required this.languages,
    required this.sourceLanguage,
    required this.title,
    required this.summary,
    required this.confirmLabel,
    this.fileNameFor,
  });

  final List<String> languages;
  final String sourceLanguage;

  final String title;

  /// Line above the list saying where the files land.
  final String summary;

  final String confirmLabel;

  /// What each language is written as. Defaults to `<lang>.json`.
  final String Function(String language)? fileNameFor;

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> languages,
    required String sourceLanguage,
    required String title,
    required String summary,
    required String confirmLabel,
    String Function(String language)? fileNameFor,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder: (_) => ExportLanguagesDialog(
        languages: languages,
        sourceLanguage: sourceLanguage,
        title: title,
        summary: summary,
        confirmLabel: confirmLabel,
        fileNameFor: fileNameFor,
      ),
    );
  }

  @override
  State<ExportLanguagesDialog> createState() => _ExportLanguagesDialogState();
}

class _ExportLanguagesDialogState extends State<ExportLanguagesDialog> {
  late final Set<String> _selected = widget.languages.toSet();

  String _fileNameFor(String language) =>
      widget.fileNameFor?.call(language) ?? '$language.json';

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return LingoDeskDialog(
      title: Text(widget.title),
      preferredWidth: 420,
      // A plain column of language tiles with no scroll of its own; a
      // workspace with many locales has to be able to reach the last one.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.summary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
            ),
          ),
          for (final language in widget.languages)
            LingoDeskCheckboxTile(
              value: _selected.contains(language),
              leading: SupportedLanguages.flagOf(language),
              title:
                  '${SupportedLanguages.nameOf(language)}'
                  '${language == widget.sourceLanguage ? ' (source)' : ''}',
              description: _fileNameFor(language),
              onChanged: (checked) {
                setState(() {
                  if (checked) {
                    _selected.add(language);
                  } else {
                    _selected.remove(language);
                  }
                });
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(
                  context,
                ).pop(widget.languages.where(_selected.contains).toList()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
