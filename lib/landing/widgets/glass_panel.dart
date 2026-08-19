import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_tokens.dart';

/// A frosted, slightly over-saturated pane that lets the page show
/// through it.
///
/// Three things sell it, and all three are needed: the blur behind, a
/// saturation bump so colour survives being blurred, and a bright hairline
/// along the top edge that reads as light catching a bevel. Without the
/// last one the panel looks like flat translucent grey.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    required this.borderRadius,
    this.blur = 22,
    this.opacity = 1,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;

  /// Fades the whole treatment in, so the bar can be plain glass over the
  /// hero and gain weight as the page scrolls under it.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final isDark = tokens.isDark;

    // Dark glass takes a light tint and light glass a white one; both keep
    // the page's own hue rather than washing to neutral grey.
    final tint = isDark
        ? Colors.white.withValues(alpha: 0.07 * opacity)
        : Colors.white.withValues(alpha: 0.62 * opacity);
    final ground = tokens.background.withValues(
      alpha: (isDark ? 0.46 : 0.30) * opacity,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          // Blurring averages colour away; pulling saturation back up is
          // what keeps the teal underneath reading as teal.
          inner: const ColorFilter.matrix(<double>[
            1.34, -0.17, -0.17, 0, 0, //
            -0.17, 1.34, -0.17, 0, 0, //
            -0.17, -0.17, 1.34, 0, 0, //
            0, 0, 0, 1, 0, //
          ]),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.alphaBlend(tint, ground), ground],
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.14 * opacity)
                  : Colors.black.withValues(alpha: 0.07 * opacity),
            ),
          ),
          child: Stack(
            children: [
              child,
              // The specular edge: a one-pixel highlight that stops short
              // of the corners, the way a rim light would.
              Positioned(
                top: 0,
                left: borderRadius.topLeft.x,
                right: borderRadius.topRight.x,
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(
                            alpha: (isDark ? 0.34 : 0.85) * opacity,
                          ),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
