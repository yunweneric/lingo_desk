import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';

/// Opens [url] in a new browser tab.
///
/// Release assets are served with a download disposition, so the same
/// call both downloads a build and follows an ordinary link.
Future<void> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

enum LandingButtonKind { primary, secondary, ghost }

/// The page's only button.
///
/// Filled buttons pick up the app's hover treatment — a 2px lift and a
/// brand-tinted glow — so the site presses the same way the product does.
class LandingButton extends StatefulWidget {
  const LandingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.url,
    this.icon,
    this.kind = LandingButtonKind.primary,
    this.busy = false,
    this.large = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Convenience for the common case: a button that is really a link.
  final String? url;

  final List<List<dynamic>>? icon;
  final LandingButtonKind kind;
  final bool busy;
  final bool large;

  /// Pins the button to an exact height, so a row of mixed controls (the
  /// navigation bar) lines up instead of each one sizing to its padding.
  final double? height;

  @override
  State<LandingButton> createState() => _LandingButtonState();
}

class _LandingButtonState extends State<LandingButton> {
  bool _hovered = false;

  bool get _enabled =>
      !widget.busy && (widget.onPressed != null || widget.url != null);

  void _activate() {
    final onPressed = widget.onPressed;
    if (onPressed != null) {
      onPressed();
      return;
    }
    final url = widget.url;
    if (url != null) {
      openLink(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final isPrimary = widget.kind == LandingButtonKind.primary;
    final isGhost = widget.kind == LandingButtonKind.ghost;

    final background = switch (widget.kind) {
      LandingButtonKind.primary => tokens.brand,
      LandingButtonKind.secondary => Colors.transparent,
      LandingButtonKind.ghost => _hovered ? tokens.active : Colors.transparent,
    };
    final foreground = isPrimary ? tokens.onBrand : tokens.foreground;
    final border = switch (widget.kind) {
      LandingButtonKind.primary => null,
      LandingButtonKind.secondary => Border.all(
        color: _hovered ? tokens.accent : tokens.border,
        width: 1.2,
      ),
      LandingButtonKind.ghost => null,
    };

    final lift = _hovered && _enabled ? -LingoDeskMotion.hoverLift : 0.0;

    return MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _enabled ? _activate : null,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          transform: Matrix4.translationValues(0, lift, 0),
          height: widget.height,
          padding: EdgeInsets.symmetric(
            horizontal: widget.large ? 28 : 20,
            vertical: widget.height != null ? 0 : (widget.large ? 18 : 14),
          ),
          decoration: BoxDecoration(
            color: _enabled ? background : background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
            border: border,
            boxShadow: isPrimary && _hovered && _enabled
                ? [
                    BoxShadow(
                      color: tokens.brand.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.busy)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              else if (widget.icon != null)
                LingoDeskIcon(
                  widget.icon!,
                  size: widget.large ? 20 : 18,
                  color: isGhost ? tokens.muted : foreground,
                ),
              if (widget.busy || widget.icon != null) const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.large ? 16 : 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: _enabled
                      ? foreground
                      : foreground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An inline text link that underlines on hover.
class LandingLink extends StatefulWidget {
  const LandingLink({
    super.key,
    required this.label,
    this.url,
    this.onPressed,
    this.muted = true,
    this.fontSize = 14.5,
  });

  final String label;
  final String? url;
  final VoidCallback? onPressed;
  final bool muted;
  final double fontSize;

  @override
  State<LandingLink> createState() => _LandingLinkState();
}

class _LandingLinkState extends State<LandingLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final base = widget.muted ? tokens.muted : tokens.foreground;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          final onPressed = widget.onPressed;
          if (onPressed != null) {
            onPressed();
            return;
          }
          final url = widget.url;
          if (url != null) {
            openLink(url);
          }
        },
        child: AnimatedDefaultTextStyle(
          duration: LingoDeskMotion.fast,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w600,
            color: _hovered ? tokens.accent : base,
            decoration: _hovered ? TextDecoration.underline : null,
            decorationColor: tokens.accent,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
