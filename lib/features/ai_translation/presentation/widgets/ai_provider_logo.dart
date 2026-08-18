import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/lingo_desk_assets.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../domain/entities/ai_provider.dart';

/// A provider's own mark.
///
/// Anthropic's clay and Gemini's gradient are part of the marks and read on
/// both themes, so they are drawn as published. OpenAI's is a solid
/// single-colour glyph that ships black — it is tinted to the theme
/// foreground instead, which is the black-or-white treatment their
/// guidelines call for and the only way it stays visible in dark mode.
class AiProviderLogo extends StatelessWidget {
  const AiProviderLogo({super.key, required this.provider, this.size = 22});

  final AiProvider provider;
  final double size;

  static String assetFor(AiProvider provider) => switch (provider) {
    AiProvider.anthropic => LingoDeskAssets.anthropicMark,
    AiProvider.openai => LingoDeskAssets.openAiMark,
    AiProvider.gemini => LingoDeskAssets.geminiMark,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return SizedBox.square(
      dimension: size,
      child: SvgPicture.asset(
        assetFor(provider),
        width: size,
        height: size,
        colorFilter: provider == AiProvider.openai
            ? ColorFilter.mode(tokens.foreground, BlendMode.srcIn)
            : null,
        // The mark is decoration beside a name that already says which
        // provider this is, so it stays out of the semantics tree.
        excludeFromSemantics: true,
      ),
    );
  }
}
