import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import 'reveal.dart';

/// The widest the page's content ever gets. Past this the gutters grow
/// instead, so a 4K window reads as a well-set page rather than a wall.
const double kLandingMaxWidth = 1180.0;

/// Height of the sticky navigation bar, used both to lay it out and to
/// offset in-page anchor scrolling so headings aren't hidden under it.
const double kLandingNavHeight = 72.0;

/// Centres content at [kLandingMaxWidth] and applies the gutter for the
/// current width class.
class LandingContainer extends StatelessWidget {
  const LandingContainer({
    super.key,
    required this.child,
    this.maxWidth = kLandingMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final gutter = context.windowSize.resolve<double>(
      compact: 20,
      medium: 28,
      expanded: 40,
      large: 48,
    );
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + gutter * 2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: child,
        ),
      ),
    );
  }
}

/// One band of the page: vertical rhythm, an optional tinted ground, and
/// a scroll anchor so the nav can jump to it.
class LandingSection extends StatelessWidget {
  const LandingSection({
    super.key,
    required this.child,
    this.anchor,
    this.tinted = false,
    this.topPadding,
    this.bottomPadding,
  });

  final Widget child;

  /// Attached so [LandingPage] can scroll this section into view.
  final GlobalKey? anchor;

  /// Paints the section on the sidebar tone, which is a step deeper than
  /// the page in dark and a step softer in light. Alternating tinted and
  /// plain sections is what gives the page its rhythm.
  final bool tinted;

  final double? topPadding;
  final double? bottomPadding;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final vertical = context.windowSize.resolve<double>(
      compact: 64,
      medium: 80,
      expanded: 104,
      large: 120,
    );

    return Container(
      key: anchor,
      width: double.infinity,
      color: tinted ? tokens.sidebar : tokens.background,
      padding: EdgeInsets.only(
        top: topPadding ?? vertical,
        bottom: bottomPadding ?? vertical,
      ),
      child: LandingContainer(child: child),
    );
  }
}

/// Eyebrow, title and optional lead-in, set consistently at the top of
/// every section.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
    this.align = TextAlign.center,
  });

  final String eyebrow;
  final String title;
  final String? body;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final centred = align == TextAlign.center;
    final lead = body;

    return Reveal(
      child: Column(
        crossAxisAlignment: centred
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            textAlign: align,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: tokens.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: align,
            style: TextStyle(
              fontSize: context.windowSize.resolve<double>(
                compact: 30,
                medium: 34,
                expanded: 40,
              ),
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: tokens.foreground,
            ),
          ),
          if (lead != null) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                lead,
                textAlign: align,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                  color: tokens.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A flat surface card matching the app's chassis: 1px hairline, 12px
/// radius, no shadow.
class LandingCard extends StatelessWidget {
  const LandingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 16,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? tokens.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? tokens.border),
      ),
      child: child,
    );
  }
}
