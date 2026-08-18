import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_checkbox.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';

/// Chip grid to toggle target languages; the source language is disabled.
///
/// The compact form, used where vertical space is tight (the create
/// dialog). Full pages use [LanguageTargetGrid] instead.
class LanguageTargetSelector extends StatelessWidget {
  const LanguageTargetSelector({
    super.key,
    required this.sourceLanguage,
    required this.selectedLanguages,
    required this.onToggled,
  });

  final String sourceLanguage;
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in SupportedLanguages.all)
          FilterChip(
            label: Text('${option.flag}  ${option.name} (${option.code})'),
            selected: selectedLanguages.contains(option.code),
            onSelected:
                option.code == sourceLanguage
                    ? null
                    : (_) => onToggled(option.code),
          ),
      ],
    );
  }
}

/// Target-language picker that fills whatever width it is given.
///
/// Lays the supported locales out as equal-width tiles, reflowing from
/// one column on a narrow pane up to as many as fit. The source language
/// keeps its tile but is locked and badged, so the base locale stays
/// visible in the same grid instead of disappearing from it.
class LanguageTargetGrid extends StatelessWidget {
  const LanguageTargetGrid({
    super.key,
    required this.sourceLanguage,
    required this.selectedLanguages,
    required this.onToggled,
    this.minTileWidth = 230,
  });

  final String sourceLanguage;
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggled;

  /// Smallest tile width before the grid drops a column.
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = ((width + spacing) / (minTileWidth + spacing))
            .floor()
            .clamp(1, 6);
        final tileWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final option in SupportedLanguages.all)
              SizedBox(
                width: tileWidth,
                child: _LanguageTile(
                  option: option,
                  selected: selectedLanguages.contains(option.code),
                  isSource: option.code == sourceLanguage,
                  onTap: () => onToggled(option.code),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One language in [LanguageTargetGrid]: flag, name, code and a check
/// box that fills in when the locale is a target.
class _LanguageTile extends StatefulWidget {
  const _LanguageTile({
    required this.option,
    required this.selected,
    required this.isSource,
    required this.onTap,
  });

  final LanguageOption option;
  final bool selected;
  final bool isSource;
  final VoidCallback onTap;

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final theme = Theme.of(context);
    final selected = widget.selected && !widget.isSource;

    final borderColor =
        widget.isSource
            ? tokens.border
            : selected
            ? (tokens.isDark
                ? LingoDeskColors.brandTealDeepBorder
                : LingoDeskColors.brandTeal)
            : _hovered
            ? LingoDeskColors.brandTeal.withValues(alpha: 0.55)
            : tokens.border;

    final fill =
        widget.isSource
            ? tokens.active
            : selected
            ? (tokens.isDark
                ? LingoDeskColors.brandTealDeep
                : LingoDeskColors.brandTealSoft)
            : _hovered
            ? tokens.active
            : tokens.card;

    final tile = AnimatedContainer(
      duration: LingoDeskMotion.fast,
      curve: LingoDeskMotion.curve,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(
          color: borderColor,
          width: selected || _hovered ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(widget.option.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: widget.isSource ? tokens.muted : tokens.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isSource ? 'Source language' : widget.option.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TileCheck(
            checked: selected,
            locked: widget.isSource,
            tokens: tokens,
          ),
        ],
      ),
    );

    if (widget.isSource) {
      return Tooltip(
        message: 'The source language cannot also be a target.',
        child: tile,
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: tile,
      ),
    );
  }
}

/// The tile's trailing state marker: the app's checkbox, or a lock on
/// the source language.
///
/// The tile owns the tap, so the box is here to be looked at — it takes
/// no pointer of its own.
class _TileCheck extends StatelessWidget {
  const _TileCheck({
    required this.checked,
    required this.locked,
    required this.tokens,
  });

  final bool checked;
  final bool locked;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return LingoDeskIcon(
        HugeIcons.strokeRoundedLockPassword,
        size: 16,
        color: tokens.muted,
      );
    }

    return IgnorePointer(
      child: LingoDeskCheckbox(
        value: checked,
        onChanged: (_) {},
        padding: EdgeInsets.zero,
      ),
    );
  }
}
