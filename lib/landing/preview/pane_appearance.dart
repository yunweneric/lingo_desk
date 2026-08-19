import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_palette.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/workspace_card.dart';
import '../../core/widgets/workspace_scaffold.dart';
import '../state/landing_controller.dart';
import 'preview_chrome.dart';

/// The appearance settings, wired to the site's own theme.
///
/// This is the pane that earns the whole exercise: it is not a picture of
/// a theme picker, it *is* the theme picker. Choosing Light/Dark or one of
/// the six palettes here repaints the entire website — nav, hero, sections
/// and the preview window itself — because the page and the product read
/// the same [LingoDeskPalette].
class PreviewAppearancePane extends StatelessWidget {
  const PreviewAppearancePane({super.key, required this.controller});

  final LandingController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PreviewBreadcrumb(
            segments: ['Workspace', 'Settings', 'Appearance'],
          ),
          const SizedBox(height: 16),
          WorkspaceSurface(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WorkspaceCardHeader(
                  title: 'Appearance',
                  subtitle: 'Follow the system theme or pick one explicitly.',
                  icon: HugeIcons.strokeRoundedPaintBoard,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _ModeButton(
                      label: 'Light',
                      icon: HugeIcons.strokeRoundedSun03,
                      selected: !controller.isDark,
                      onTap: controller.isDark
                          ? controller.toggleBrightness
                          : null,
                      first: true,
                    ),
                    _ModeButton(
                      label: 'Dark',
                      icon: HugeIcons.strokeRoundedMoon02,
                      selected: controller.isDark,
                      onTap: controller.isDark
                          ? null
                          : controller.toggleBrightness,
                      last: true,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'This really is the setting — it repaints the whole '
                        'page, not just this window.',
                        style: TextStyle(fontSize: 12.5, color: tokens.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: WorkspaceSurface(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WorkspaceCardHeader(
                    title: 'Theme',
                    subtitle:
                        'Six palettes. Each one restyles the whole app, '
                        'not just the accent.',
                    icon: HugeIcons.strokeRoundedColors,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                      children: [
                        for (final variant in LingoDeskThemeVariant.values)
                          _VariantTile(
                            variant: variant,
                            selected: controller.variant == variant,
                            isDark: controller.isDark,
                            onTap: () => controller.setVariant(variant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One half of the light/dark segmented control.
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.first = false,
    this.last = false,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    const radius = Radius.circular(999);

    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tokens.brandFill : tokens.card,
            border: Border.all(
              color: selected ? tokens.brandFillBorder : tokens.border,
            ),
            borderRadius: BorderRadius.only(
              topLeft: first ? radius : Radius.zero,
              bottomLeft: first ? radius : Radius.zero,
              topRight: last ? radius : Radius.zero,
              bottomRight: last ? radius : Radius.zero,
            ),
          ),
          child: Row(
            children: [
              LingoDeskIcon(
                icon,
                size: 16,
                color: selected ? tokens.onBrandFill : tokens.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? tokens.onBrandFill : tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selectable palette, previewed in its own colours at the brightness
/// currently showing — so the grid reads as six miniature apps.
class _VariantTile extends StatefulWidget {
  const _VariantTile({
    required this.variant,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final LingoDeskThemeVariant variant;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_VariantTile> createState() => _VariantTileState();
}

class _VariantTileState extends State<_VariantTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final preview = widget.variant.palette.scheme(widget.isDark);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: preview.background,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
            border: Border.all(
              color: widget.selected
                  ? tokens.accent
                  : (_hovered ? tokens.brandFillBorder : tokens.border),
              width: widget.selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.variant.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: preview.foreground,
                      ),
                    ),
                  ),
                  if (widget.selected)
                    Container(
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: preview.brand,
                        shape: BoxShape.circle,
                      ),
                      child: LingoDeskIcon(
                        HugeIcons.strokeRoundedTick02,
                        size: 12,
                        color: preview.onBrand,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  widget.variant.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: preview.muted,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  for (final color in [
                    preview.brand,
                    preview.accent,
                    preview.brandFill,
                    preview.card,
                    preview.active,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: preview.border),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
