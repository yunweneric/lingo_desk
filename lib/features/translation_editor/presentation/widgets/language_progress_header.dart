import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/touch.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../bloc/translation_editor_bloc.dart';
import '../bloc/translation_editor_event.dart';
import '../bloc/translation_editor_state.dart';

/// Real-time completion bars for every target language.
class LanguageProgressHeader extends StatelessWidget {
  const LanguageProgressHeader({super.key, required this.state});

  final TranslationEditorLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    final languages = state.app.targetLanguages;

    return ResponsiveBuilder(
      builder: (context, size, constraints) {
        // A fixed 190px tile leaves a ragged gutter down the right of a
        // phone and a half-empty last row on a laptop. Fit as many whole
        // tiles as the pane takes and let them share it out evenly.
        const spacing = 12.0;
        const minTileWidth = 170.0;
        final columns = ((constraints.maxWidth + spacing) /
                (minTileWidth + spacing))
            .floor()
            .clamp(1, 8);
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < languages.length; index++)
              FadeSlideIn.staggered(
                index: index,
                child: SizedBox(
                  width: tileWidth,
                  child: _LanguageProgressTile(
                    language: languages[index],
                    progress: state.completionFor(languages[index]),
                    missing: state.missingCountFor(languages[index]),
                    translatable: state.translatableMissingFor(
                      languages[index],
                    ),
                    isBusy: state.aiJob != null,
                    tokens: tokens,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Side of the per-language AI button. A thumb needs the full target; a
/// pointer would rather the tile stayed compact.
final double _aiButtonSide = isTouchPlatform ? kTouchTarget : 22;

class _LanguageProgressTile extends StatelessWidget {
  const _LanguageProgressTile({
    required this.language,
    required this.progress,
    required this.missing,
    required this.translatable,
    required this.isBusy,
    required this.tokens,
  });

  final String language;
  final double progress;
  final int missing;

  /// Missing cells the AI could actually fill — the rest have no source
  /// text, so offering to translate them would promise something false.
  final int translatable;

  /// A pass is already running; a second one would fight it for the grid.
  final bool isBusy;

  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              if (translatable > 0 && !isBusy)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: SizedBox.square(
                    // 22px is a pointer's target, not a thumb's.
                    dimension: _aiButtonSide,
                    child: IconButton(
                      tooltip:
                          'AI translate $translatable missing '
                          '${translatable == 1 ? 'string' : 'strings'}',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints.tightFor(
                        width: _aiButtonSide,
                        height: _aiButtonSide,
                      ),
                      onPressed: () => context
                          .read<TranslationEditorBloc>()
                          .add(AiTranslateEvent([language])),
                      icon: const LingoDeskIcon(
                        HugeIcons.strokeRoundedSparkles,
                        size: 14,
                        color: LingoDeskColors.brandTeal,
                      ),
                    ),
                  ),
                ),
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
