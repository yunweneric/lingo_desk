import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';

/// Dialog to choose which languages to export as JSON files.
///
/// Returns the selected language codes, or null when canceled.
class ExportLanguagesDialog extends StatefulWidget {
  const ExportLanguagesDialog({
    super.key,
    required this.languages,
    required this.sourceLanguage,
  });

  final List<String> languages;
  final String sourceLanguage;

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> languages,
    required String sourceLanguage,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder:
          (_) => ExportLanguagesDialog(
            languages: languages,
            sourceLanguage: sourceLanguage,
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
    return AlertDialog(
      title: const Text('Export JSON files'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final language in widget.languages)
              CheckboxListTile(
                value: _selected.contains(language),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  '$language.json - ${SupportedLanguages.nameOf(language)}'
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
          child: const Text('Export'),
        ),
      ],
    );
  }
}
