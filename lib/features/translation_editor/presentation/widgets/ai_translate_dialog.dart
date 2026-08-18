import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_checkbox.dart';
import '../../../../core/widgets/lingo_desk_dialog.dart';
import '../bloc/translation_editor_state.dart';

/// Picks which target languages an AI pass should fill.
///
/// Only languages with something missing are offered, and each row carries
/// its count, so the dialog doubles as the answer to "where are the gaps".
/// Returns the selected language codes, or null when canceled.
class AiTranslateDialog extends StatefulWidget {
  const AiTranslateDialog({
    super.key,
    required this.state,
    required this.providerLabel,
    required this.model,
  });

  final TranslationEditorLoaded state;
  final String providerLabel;
  final String model;

  static Future<List<String>?> show(
    BuildContext context, {
    required TranslationEditorLoaded state,
    required String providerLabel,
    required String model,
  }) {
    return showDialog<List<String>>(
      context: context,
      builder: (_) => AiTranslateDialog(
        state: state,
        providerLabel: providerLabel,
        model: model,
      ),
    );
  }

  @override
  State<AiTranslateDialog> createState() => _AiTranslateDialogState();
}

class _AiTranslateDialogState extends State<AiTranslateDialog> {
  late final Map<String, int> _missing = {
    for (final language in widget.state.app.targetLanguages)
      if (widget.state.translatableMissingFor(language) > 0)
        language: widget.state.translatableMissingFor(language),
  };

  late final Set<String> _selected = _missing.keys.toSet();

  int get _selectedCount =>
      _selected.fold(0, (sum, language) => sum + (_missing[language] ?? 0));

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final allSelected = _selected.length == _missing.length;

    return LingoDeskDialog(
      title: const Text('AI translate'),
      preferredWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Only empty cells are filled — translations you already have '
              'are never overwritten.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
            ),
          ),
          if (_missing.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Every target language is complete.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() {
                  if (allSelected) {
                    _selected.clear();
                  } else {
                    _selected.addAll(_missing.keys);
                  }
                }),
                child: Text(allSelected ? 'Clear all' : 'Select all'),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in _missing.entries)
                      LingoDeskCheckboxTile(
                        value: _selected.contains(entry.key),
                        leading: SupportedLanguages.flagOf(entry.key),
                        title: SupportedLanguages.nameOf(entry.key),
                        trailing: Text(
                          '${entry.value} missing',
                          style: LingoDeskTheme.codeStyle.copyWith(
                            color: tokens.muted,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked) {
                              _selected.add(entry.key);
                            } else {
                              _selected.remove(entry.key);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Using ${widget.providerLabel} · ${widget.model}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
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
              : () => Navigator.of(context).pop(
                  widget.state.app.targetLanguages
                      .where(_selected.contains)
                      .toList(),
                ),
          child: Text(
            _selectedCount == 0
                ? 'Translate'
                : 'Translate $_selectedCount string'
                      '${_selectedCount == 1 ? '' : 's'}',
          ),
        ),
      ],
    );
  }
}
