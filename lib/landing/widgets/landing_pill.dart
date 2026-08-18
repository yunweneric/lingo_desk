import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_tokens.dart';

/// A small rounded label: the MIT badge, the platform row, locale chips.
class LandingPill extends StatelessWidget {
  const LandingPill({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.emphasis = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;

  /// Anything richer than an icon — a flag emoji, a provider logo.
  final Widget? leading;

  /// Paints the pill in the brand tint instead of the neutral surface.
  final bool emphasis;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final background = emphasis ? tokens.brandFill : tokens.card;
    final border = emphasis ? tokens.brandFillBorder : tokens.border;
    final foreground = emphasis ? tokens.onBrandFill : tokens.muted;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 7),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return pill;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: pill),
    );
  }
}

/// One of the six targets the single codebase ships to.
///
/// [available] is false for the platforms no workflow publishes a build
/// for — they still belong on the list, they just point at the source
/// build rather than a download.
class PlatformTile extends StatefulWidget {
  const PlatformTile({
    super.key,
    required this.label,
    required this.icon,
    required this.available,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool available;
  final VoidCallback? onTap;

  @override
  State<PlatformTile> createState() => _PlatformTileState();
}

class _PlatformTileState extends State<PlatformTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          transform: Matrix4.translationValues(
            0,
            _hovered ? -LingoDeskMotion.hoverLift : 0,
            0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: _hovered ? tokens.active : tokens.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? tokens.brandFillBorder : tokens.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 24, color: tokens.accent),
              const SizedBox(height: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.foreground,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.available ? 'Prebuilt' : 'From source',
                style: TextStyle(fontSize: 11.5, color: tokens.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
