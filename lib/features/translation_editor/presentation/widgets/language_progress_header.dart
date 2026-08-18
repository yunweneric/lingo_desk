import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../bloc/translation_editor_state.dart';

/// Real-time completion bars for every target language.
class LanguageProgressHeader extends StatelessWidget {
  const LanguageProgressHeader({super.key, required this.state});

  final TranslationEditorLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    final languages = state.app.targetLanguages;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var index = 0; index < languages.length; index++)
          FadeSlideIn.staggered(
            index: index,
            child: _LanguageProgressTile(
              language: languages[index],
              progress: state.completionFor(languages[index]),
              missing: state.missingCountFor(languages[index]),
              tokens: tokens,
            ),
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
                '${SupportedLanguages.flagOf(language)} ',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                language.toUpperCase(),
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.foreground,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              AnimatedCountText(
                value: progress * 100,
                suffix: '%',
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          WorkspaceProgressBar(
            value: progress,
            isComplete: missing == 0,
            minHeight: 6,
            backgroundColor: tokens.card,
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: LingoDeskMotion.standard,
            switchInCurve: LingoDeskMotion.curve,
            child: Text(
              missing == 0 ? 'Complete' : '$missing missing',
              key: ValueKey<bool>(missing == 0),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: missing == 0 ? LingoDeskColors.complete : tokens.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
