import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_palette.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../../core/localization/export.dart';

/// Theme mode, the six palette variants, and a live swatch preview of
/// whichever combination is currently resolved.
class SettingsAppearanceCard extends StatelessWidget {
  const SettingsAppearanceCard({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkspaceCardHeader(
                title: LocaleKeys.navAppearance.tr(),
                subtitle: LocaleKeys.settingsAppearanceSubtitle.tr(),
                icon: HugeIcons.strokeRoundedPaintBoard,
              ),
              const SizedBox(height: 22),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(LocaleKeys.commonThemeSystem.tr()),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(LocaleKeys.commonThemeLight.tr()),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(LocaleKeys.commonThemeDark.tr()),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) =>
                    settings.setThemeMode(selection.first),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _Swatch(
                    color: tokens.background,
                    label: LocaleKeys.settingsSwatchBackground.tr(),
                  ),
                  const SizedBox(width: 8),
                  _Swatch(
                    color: tokens.card,
                    label: LocaleKeys.settingsSwatchCard.tr(),
                  ),
                  const SizedBox(width: 8),
                  _Swatch(
                    color: tokens.active,
                    label: LocaleKeys.settingsSwatchActive.tr(),
                  ),
                  const SizedBox(width: 8),
                  _Swatch(
                    color: tokens.brand,
                    label: LocaleKeys.settingsSwatchBrand.tr(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WorkspaceSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkspaceCardHeader(
                title: LocaleKeys.commonTheme.tr(),
                subtitle: LocaleKeys.settingsThemeSubtitle.tr(),
                icon: HugeIcons.strokeRoundedColors,
              ),
              const SizedBox(height: 22),
              // A fixed count rather than an extent, so the six cards stay
              // in a tidy grid instead of reflowing to one long column on
              // a narrow settings pane.
              ResponsiveBuilder(
                builder: (context, size, constraints) {
                  final columns = size.resolve(
                    compact: 1,
                    medium: 2,
                    expanded: 3,
                  );
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.25,
                    children: [
                      for (final variant in LingoDeskThemeVariant.values)
                        _VariantTile(
                          variant: variant,
                          selected: settings.themeVariant == variant,
                          isDark: tokens.isDark,
                          onTap: () => settings.setThemeVariant(variant),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One selectable palette: its own colours previewed at the brightness
/// the app is currently showing, so the card is an honest sample.
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
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // The tile paints in the variant's own background so the
            // grid reads as six miniature apps side by side.
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
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: preview.foreground,
                      ),
                    ),
                  ),
                  if (widget.selected)
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: preview.brand,
                        shape: BoxShape.circle,
                      ),
                      child: LingoDeskIcon(
                        HugeIcons.strokeRoundedTick02,
                        size: 13,
                        color: preview.onBrand,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  widget.variant.description.tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: preview.muted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                        width: 22,
                        height: 22,
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

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
