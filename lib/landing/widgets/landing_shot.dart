import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';

/// A product screenshot.
///
/// The images live in `web/` rather than in the pubspec asset bundle:
/// they are only ever needed by the web entry point, and serving them
/// keeps them out of the macOS, Windows and Android builds entirely. They
/// stream in over the same origin, so a relative path resolves against
/// whatever `--base-href` the site was built with.
///
/// The captures already carry macOS window chrome, so this adds only a
/// soft brand glow behind them and never a second frame.
class LandingShot extends StatelessWidget {
  const LandingShot({
    super.key,
    required this.name,
    required this.semanticLabel,
    this.glow = true,
    this.aspectRatio = 1560 / 1047,
  });

  /// Filename inside `web/img/`.
  final String name;

  final String semanticLabel;
  final bool glow;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: tokens.brand.withValues(alpha: 0.28),
                    blurRadius: 90,
                    spreadRadius: -20,
                    offset: const Offset(0, 30),
                  ),
                ]
              : null,
        ),
        child: Image.network(
          'img/$name',
          fit: BoxFit.contain,
          semanticLabel: semanticLabel,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) {
              return child;
            }
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: LingoDeskMotion.slow,
              curve: LingoDeskMotion.entrance,
              child: child,
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }
            return _ShotPlaceholder(tokens: tokens);
          },
          errorBuilder: (context, error, stackTrace) =>
              _ShotPlaceholder(tokens: tokens, failed: true),
        ),
      ),
    );
  }
}

class _ShotPlaceholder extends StatelessWidget {
  const _ShotPlaceholder({required this.tokens, this.failed = false});

  final LingoDeskTokens tokens;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      alignment: Alignment.center,
      child: failed
          ? Icon(Icons.image_not_supported_outlined, color: tokens.muted)
          : SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
              ),
            ),
    );
  }
}
