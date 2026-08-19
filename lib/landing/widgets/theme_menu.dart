import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_palette.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/lingo_desk_menu.dart';
import '../state/landing_controller.dart';

/// A swatch dot showing a variant's brand colour, ringed in its accent.
class PaletteDot extends StatelessWidget {
  const PaletteDot({
    super.key,
    required this.variant,
    required this.isDark,
    this.size = 16,
  });

  final LingoDeskThemeVariant variant;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = LingoDeskPalettes.of(variant).scheme(isDark);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.brand,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.accent, width: size / 10),
      ),
    );
  }
}

/// The navigation's theme picker: the six palettes the app ships, on the
/// same menu surface the product uses ([lingoDeskMenuStyle]).
///
/// Picking one repaints the entire page — which is the argument the
/// "built with Flutter" section is making, so it belongs in the nav too.
class ThemeMenuButton extends StatefulWidget {
  const ThemeMenuButton({
    super.key,
    required this.controller,
    this.showLabel = true,
    this.height,
  });

  final LandingController controller;

  /// Drops the palette name, leaving swatch and chevron, when the bar is
  /// short of room.
  final bool showLabel;

  /// Pins the trigger to an exact height to match its neighbours.
  final double? height;

  @override
  State<ThemeMenuButton> createState() => _ThemeMenuButtonState();
}

class _ThemeMenuButtonState extends State<ThemeMenuButton> {
  final MenuController _menu = MenuController();
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final controller = widget.controller;

    return MenuAnchor(
      controller: _menu,
      style: lingoDeskMenuStyle(tokens),
      alignmentOffset: const Offset(0, 8),
      menuChildren: [
        SizedBox(
          width: 268,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(
                  'THEME',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: tokens.muted,
                  ),
                ),
              ),
              for (final variant in LingoDeskThemeVariant.values)
                _VariantRow(
                  variant: variant,
                  isDark: controller.isDark,
                  selected: controller.variant == variant,
                  onTap: () {
                    controller.setVariant(variant);
                    _menu.close();
                  },
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Divider(color: tokens.border, height: 1),
              ),
              _VariantRow.brightness(
                isDark: controller.isDark,
                onTap: () {
                  controller.toggleBrightness();
                  _menu.close();
                },
              ),
            ],
          ),
        ),
      ],
      builder: (context, menu, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => menu.isOpen ? menu.close() : menu.open(),
            child: AnimatedContainer(
              duration: LingoDeskMotion.fast,
              curve: LingoDeskMotion.curve,
              height: widget.height,
              padding: EdgeInsets.symmetric(
                horizontal: widget.showLabel ? 14 : 11,
                vertical: widget.height == null ? 11 : 0,
              ),
              decoration: BoxDecoration(
                color: _hovered || menu.isOpen ? tokens.active : tokens.card,
                borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PaletteDot(
                    variant: controller.variant,
                    isDark: controller.isDark,
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(width: 9),
                    Text(
                      controller.variant.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.foreground,
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  LingoDeskIcon(
                    HugeIcons.strokeRoundedArrowDown01,
                    size: 15,
                    color: tokens.muted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One row of the theme menu: swatch, name, description, tick.
class _VariantRow extends StatefulWidget {
  const _VariantRow({
    required this.variant,
    required this.isDark,
    required this.selected,
    required this.onTap,
  }) : brightnessRow = false;

  /// The light/dark switch that closes the menu.
  const _VariantRow.brightness({required this.isDark, required this.onTap})
    : variant = LingoDeskThemeVariant.teal,
      selected = false,
      brightnessRow = true;

  final LingoDeskThemeVariant variant;
  final bool isDark;
  final bool selected;
  final bool brightnessRow;
  final VoidCallback onTap;

  @override
  State<_VariantRow> createState() => _VariantRowState();
}

class _VariantRowState extends State<_VariantRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final isBrightness = widget.brightnessRow;

    final label = isBrightness
        ? (widget.isDark ? 'Switch to light' : 'Switch to dark')
        : widget.variant.label;
    final description = isBrightness ? null : widget.variant.description;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected
                ? tokens.brandFill
                : (_hovered ? tokens.active : Colors.transparent),
            borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
          ),
          child: Row(
            children: [
              if (isBrightness)
                LingoDeskIcon(
                  widget.isDark
                      ? HugeIcons.strokeRoundedSun03
                      : HugeIcons.strokeRoundedMoon02,
                  size: 16,
                  color: tokens.foreground,
                )
              else
                PaletteDot(variant: widget.variant, isDark: widget.isDark),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: widget.selected
                            ? tokens.onBrandFill
                            : tokens.foreground,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: tokens.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.selected) ...[
                const SizedBox(width: 8),
                LingoDeskIcon(
                  HugeIcons.strokeRoundedTick02,
                  size: 15,
                  color: tokens.onBrandFill,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
