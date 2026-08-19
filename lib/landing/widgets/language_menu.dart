import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/languages.dart';
import '../../core/localization/export.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/lingo_desk_menu.dart';

/// The navigation's language picker.
///
/// A site about translating software that only speaks English would be
/// making the wrong argument, so every locale the product ships is offered
/// here. The choice goes through [AppLocalization.setLocale], which
/// persists it — a reload comes back in the same language.
class LanguageMenuButton extends StatefulWidget {
  const LanguageMenuButton({super.key, this.showLabel = true, this.height});

  /// Drops the language name, leaving just the flag and the chevron, when
  /// the bar is short of room. The flag still says which language it is.
  final bool showLabel;

  /// Pins the trigger to an exact height to match its neighbours.
  final double? height;

  @override
  State<LanguageMenuButton> createState() => _LanguageMenuButtonState();
}

class _LanguageMenuButtonState extends State<LanguageMenuButton> {
  final MenuController _menu = MenuController();
  final ScrollController _scroll = ScrollController();
  bool _hovered = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final active = AppLocalization.languageCodeOf(context);

    return MenuAnchor(
      controller: _menu,
      style: lingoDeskMenuStyle(tokens),
      alignmentOffset: const Offset(0, 8),
      menuChildren: [
        SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(
                  LocaleKeys.landingNavLanguage.tr().toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: tokens.muted,
                  ),
                ),
              ),
              // Twenty locales are more than a menu can show at once, so
              // the list scrolls rather than running off the viewport.
              //
              // A scroll view rather than a ListView: MenuAnchor measures
              // its panel with IntrinsicWidth, and a shrink-wrapping
              // ListView viewport cannot answer an intrinsic query — it
              // throws the moment the menu opens. SingleChildScrollView
              // passes the question down to its child.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Scrollbar(
                  controller: _scroll,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in SupportedLanguages.all)
                          _LanguageRow(
                            option: option,
                            selected: option.code == active,
                            onTap: () {
                              AppLocalization.setLocale(context, option.code);
                              _menu.close();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
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
          child: Semantics(
            button: true,
            label: LocaleKeys.landingNavLanguage.tr(),
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
                    Text(
                      SupportedLanguages.flagOf(active),
                      style: const TextStyle(fontSize: 15),
                    ),
                    if (widget.showLabel) ...[
                      const SizedBox(width: 9),
                      Text(
                        SupportedLanguages.nameOf(active),
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
          ),
        );
      },
    );
  }
}

/// One row of the language menu: flag, name, code, tick.
class _LanguageRow extends StatefulWidget {
  const _LanguageRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_LanguageRow> createState() => _LanguageRowState();
}

class _LanguageRowState extends State<_LanguageRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: _hovered ? tokens.active : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                widget.option.flag,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  SupportedLanguages.nameOf(widget.option.code),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: widget.selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.selected
                        ? tokens.accent
                        : tokens.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.option.code.toUpperCase(),
                style: LingoDeskTheme.codeStyle.copyWith(
                  fontSize: 11,
                  color: tokens.muted,
                ),
              ),
              if (widget.selected) ...[
                const SizedBox(width: 8),
                LingoDeskIcon(
                  HugeIcons.strokeRoundedTick02,
                  size: 15,
                  color: tokens.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
