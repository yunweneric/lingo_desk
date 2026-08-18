import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';

/// Dialog to choose which languages go into the exported archive.
///
/// Returns the selected language codes, or null when canceled.
class ExportLanguagesDialog extends StatefulWidget {
  const ExportLanguagesDialog({
    super.key,
    required this.languages,
    required this.sourceLanguage,
    required this.archiveName,
  });

  final List<String> languages;
  final String sourceLanguage;

  /// Name of the single archive the selected files are bundled into.
  final String archiveName;

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> languages,
    required String sourceLanguage,
    required String archiveName,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder:
          (_) => ExportLanguagesDialog(
            languages: languages,
            sourceLanguage: sourceLanguage,
            archiveName: archiveName,
          ),
    );
  }

  @override
  State<ExportLanguagesDialog> createState() => _ExportLanguagesDialogState();
}

class _ExportLanguagesDialogState extends State<ExportLanguagesDialog> {
  late final Set<String> _selected = widget.languages.toSet();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return AlertDialog(
      title: const Text('Export as ZIP'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'The selected files are bundled into a single archive, '
                '${widget.archiveName}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
              ),
            ),
            for (final language in widget.languages)
              CheckboxListTile(
                value: _selected.contains(language),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  '${SupportedLanguages.flagOf(language)}  $language.json - ${SupportedLanguages.nameOf(language)}'
                  '${language == widget.sourceLanguage ? ' (source)' : ''}',
                ),
                onChanged: (checked) {
                  setState(() {
                    if (checked ?? false) {
                      _selected.add(language);
                    } else {
                      _selected.remove(language);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _selected.isEmpty
                  ? null
                  : () => Navigator.of(
                    context,
                  ).pop(widget.languages.where(_selected.contains).toList()),
          child: const Text('Download ZIP'),
        ),
      ],
    );
  }
}
