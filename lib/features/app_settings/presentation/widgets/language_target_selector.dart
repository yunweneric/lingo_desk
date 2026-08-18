import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';

/// Chip grid to toggle target languages; the source language is disabled.
class LanguageTargetSelector extends StatelessWidget {
  const LanguageTargetSelector({
    super.key,
    required this.sourceLanguage,
    required this.selectedLanguages,
    required this.onToggled,
  });

  final String sourceLanguage;
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggled;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in SupportedLanguages.all)
          FilterChip(
            label: Text('${option.flag}  ${option.name} (${option.code})'),
            selected: selectedLanguages.contains(option.code),
            onSelected:
                option.code == sourceLanguage
                    ? null
                    : (_) => onToggled(option.code),
            checkmarkColor: tokens.foreground,
          ),
      ],
    );
  }
}
