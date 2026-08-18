import 'package:flutter/material.dart';

import '../../core/constants/languages.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';

/// The twenty locales the product ships with, drifting past.
///
/// The list is [SupportedLanguages.all] itself rather than a copy, so the
/// site can never advertise a language the app does not offer.
class LocaleStrip extends StatefulWidget {
  const LocaleStrip({super.key});

  @override
  State<LocaleStrip> createState() => _LocaleStripState();
}

class _LocaleStripState extends State<LocaleStrip>
    with SingleTickerProviderStateMixin {
  static const double _itemWidth = 168;
  static const Duration _loop = Duration(seconds: 90);

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: _loop,
  );

  @override
  void initState() {
    super.initState();
    _drift.repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    const locales = SupportedLanguages.all;
    final runWidth = _itemWidth * locales.length;
    final moving = LingoDeskMotion.enabled(context);

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final locale in locales)
          SizedBox(
            width: _itemWidth,
            child: _LocaleChip(
              flag: locale.flag,
              code: locale.code,
              name: locale.name,
            ),
          ),
      ],
    );

    return Container(
      width: double.infinity,
      color: tokens.sidebar,
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Column(
        children: [
          Text(
            '20 LOCALES BUILT IN · ADD ANY OTHER IN SETTINGS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: tokens.muted,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 34,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  tokens.sidebar,
                  tokens.sidebar.withValues(alpha: 0),
                  tokens.sidebar.withValues(alpha: 0),
                  tokens.sidebar,
                ],
                stops: const [0, 0.08, 0.92, 1],
              ).createShader(bounds),
              blendMode: BlendMode.dstOut,
              child: ClipRect(
                child: moving
                    ? AnimatedBuilder(
                        animation: _drift,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(-_drift.value * runWidth, 0),
                          child: child,
                        ),
                        // Two runs side by side: as the first slides out
                        // the second is already in place, so the loop
                        // never shows a seam.
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [row, row],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: row,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocaleChip extends StatelessWidget {
  const _LocaleChip({
    required this.flag,
    required this.code,
    required this.name,
  });

  final String flag;
  final String code;
  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 17)),
        const SizedBox(width: 9),
        Text(
          code.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tokens.foreground,
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: tokens.muted),
          ),
        ),
      ],
    );
  }
}
