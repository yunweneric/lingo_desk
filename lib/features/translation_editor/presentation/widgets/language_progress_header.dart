import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../bloc/translation_editor_state.dart';

/// Real-time completion bars for every target language.
class LanguageProgressHeader extends StatelessWidget {
  const LanguageProgressHeader({super.key, required this.state});

  final TranslationEditorLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final language in state.app.targetLanguages)
          _LanguageProgressTile(
            language: language,
            progress: state.completionFor(language),
            missing: state.missingCountFor(language),
            tokens: tokens,
          ),
      ],
    );
  }
}

class _LanguageProgressTile extends StatelessWidget {
  const _LanguageProgressTile({
    required this.language,
    required this.progress,
    required this.missing,
    required this.tokens,
  });

  final String language;
  final double progress;
  final int missing;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.active,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                language.toUpperCase(),
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.foreground,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            color:
                missing == 0
                    ? LingoDeskColors.complete
                    : LingoDeskColors.brandTeal,
            backgroundColor: tokens.card,
          ),
          const SizedBox(height: 6),
          Text(
            missing == 0 ? 'Complete' : '$missing missing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: missing == 0 ? LingoDeskColors.complete : tokens.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
