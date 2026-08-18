import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_animations.dart';
import 'lingo_desk_field.dart';
import 'lingo_desk_icon.dart';

/// The panel every menu surface in the app drops: a card-coloured sheet
/// with the 12px radius, a hairline border and a soft shadow.
///
/// Shared by [LingoDeskMenuButton] and [LingoDeskDropdown] so a row menu
/// and a dropdown opened side by side are the same object.
MenuStyle lingoDeskMenuStyle(LingoDeskTokens tokens) {
  return MenuStyle(
    backgroundColor: WidgetStatePropertyAll(tokens.card),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: WidgetStatePropertyAll(
      Colors.black.withValues(alpha: tokens.isDark ? 0.6 : 0.14),
    ),
    elevation: const WidgetStatePropertyAll(10),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        side: BorderSide(color: tokens.border),
      ),
    ),
  );
}

/// One row inside a menu panel.
///
/// Carries the optional chrome menus and dropdowns both need: a leading
/// icon or emoji, a second description line, a trailing mono tag, a tick
/// gutter for pickable lists, and a red treatment for destructive actions.
class LingoDeskMenuTile extends StatelessWidget {
  const LingoDeskMenuTile({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leadingText,
    this.description,
    this.trailingText,
    this.selected = false,
    this.destructive = false,
    this.enabled = true,
    this.monospace = false,
    this.showSelection = false,
    this.size = LingoDeskFieldSize.standard,
  });

  final String label;
  final VoidCallback onPressed;
  final List<List<dynamic>>? icon;
  final String? leadingText;
  final String? description;
  final String? trailingText;
  final bool selected;

  /// Paints the row red — deletes and anything else without an undo.
  final bool destructive;

  final bool enabled;
  final bool monospace;

  /// Reserves the tick gutter. On for pickers, off for action menus.
  final bool showSelection;

  final LingoDeskFieldSize size;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final selectedColor = tokens.isDark
        ? LingoDeskColors.brandTealDeep
        : LingoDeskColors.brandTealSoft;
    final contentColor = !enabled
        ? tokens.muted
        : destructive
        ? LingoDeskColors.error
        : tokens.foreground;
    final labelStyle =
        (monospace
                ? LingoDeskTheme.codeStyle
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(
              fontSize: size.fontSize,
              color: contentColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: MenuItemButton(
        onPressed: enabled ? onPressed : null,
        style: ButtonStyle(
          animationDuration: LingoDeskMotion.fast,
          backgroundColor: WidgetStatePropertyAll(
            selected ? selectedColor : Colors.transparent,
          ),
          overlayColor: WidgetStatePropertyAll(
            destructive
                ? LingoDeskColors.error.withValues(alpha: 0.1)
                : (tokens.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : LingoDeskColors.activeLight),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: size.gap),
          ),
          minimumSize: const WidgetStatePropertyAll(Size.zero),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),

          child: Row(
            children: [
              if (leadingText != null) ...[
                Text(
                  leadingText!,
                  style: TextStyle(fontSize: size.fontSize + 2),
                ),
                SizedBox(width: size.gap),
              ] else if (icon != null) ...[
                LingoDeskIcon(
                  icon!,
                  size: size.iconSize,
                  color: destructive
                      ? LingoDeskColors.error
                      : selected
                      ? LingoDeskColors.brandTeal
                      : tokens.muted,
                ),
                SizedBox(width: size.gap),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null) ...[
                SizedBox(width: size.gap),
                Text(
                  trailingText!,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.muted,
                    fontSize: size.fontSize - 2,
                  ),
                ),
              ],
              if (showSelection) ...[
                SizedBox(width: size.gap),
                SizedBox(
                  width: size.iconSize,
                  child: selected
                      ? LingoDeskIcon(
                          HugeIcons.strokeRoundedTick02,
                          size: size.iconSize,
                          color: LingoDeskColors.brandTeal,
                        )
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One entry in a [LingoDeskMenuButton].
class LingoDeskMenuItem<T> {
  const LingoDeskMenuItem({
    required T this.value,
    required this.label,
    this.icon,
    this.description,
    this.destructive = false,
    this.enabled = true,
  }) : isDivider = false;

  /// A hairline separating groups of actions.
  const LingoDeskMenuItem.divider()
    : value = null,
      label = '',
      icon = null,
      description = null,
      destructive = false,
      enabled = false,
      isDivider = true;

  final T? value;
  final String label;
  final List<List<dynamic>>? icon;
  final String? description;
  final bool destructive;
  final bool enabled;
  final bool isDivider;
}

/// The overflow menu behind a table row's "..." — and any other action
/// list hung off a small trigger.
///
/// The default trigger is the menu icon itself: a quiet glyph that fills
/// on hover and turns teal while its menu is open. Pass [child] to hang
/// the same menu off something else (a toolbar button, an avatar).
/// Passing [selectedValue] turns it into a picker, ticking the live one.
class LingoDeskMenuButton<T> extends StatefulWidget {
  const LingoDeskMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon = HugeIcons.strokeRoundedMoreHorizontal,
    this.tooltip = 'More',
    this.child,
    this.selectedValue,
    this.enabled = true,
    this.menuWidth = 220,
    this.alignMenuEnd = true,
    this.triggerSize = 32,
    this.iconSize = 19,
  });

  final List<LingoDeskMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  /// Glyph for the default trigger; ignored when [child] is given.
  final List<List<dynamic>> icon;

  final String tooltip;

  /// Custom trigger. It gets the open/hover treatment of whatever it
  /// draws itself — only the menu behaviour comes from here.
  final Widget? child;

  /// When set, the matching row is ticked and highlighted.
  final T? selectedValue;

  final bool enabled;
  final double menuWidth;

  /// Hangs the panel off the trigger's right edge, so a menu at the end
  /// of a table row opens inward instead of off the screen.
  final bool alignMenuEnd;

  final double triggerSize;
  final double iconSize;

  @override
  State<LingoDeskMenuButton<T>> createState() => _LingoDeskMenuButtonState<T>();
}

class _LingoDeskMenuButtonState<T> extends State<LingoDeskMenuButton<T>> {
  final _menuController = MenuController();
  bool _open = false;

  void _toggle() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final isEnabled = widget.enabled && widget.items.isNotEmpty;

    return MenuAnchor(
      controller: _menuController,
      onOpen: () => setState(() => _open = true),
      onClose: () => setState(() => _open = false),
      alignmentOffset: widget.alignMenuEnd
          ? Offset(-widget.menuWidth, 6)
          : const Offset(0, 6),
      style: widget.alignMenuEnd
          ? lingoDeskMenuStyle(
              tokens,
            ).copyWith(alignment: Alignment.bottomRight)
          : lingoDeskMenuStyle(tokens),
      menuChildren: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.menuWidth,
            maxWidth: widget.menuWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in widget.items)
                if (item.isDivider)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Divider(height: 1, color: tokens.border),
                  )
                else
                  LingoDeskMenuTile(
                    label: item.label,
                    icon: item.icon,
                    description: item.description,
                    destructive: item.destructive,
                    enabled: item.enabled,
                    selected:
                        widget.selectedValue != null &&
                        item.value == widget.selectedValue,
                    showSelection: widget.selectedValue != null,
                    onPressed: () => widget.onSelected(item.value as T),
                  ),
            ],
          ),
        ),
      ],
      builder: (context, controller, child) {
        final trigger =
            widget.child ??
            _MenuIcon(
              icon: widget.icon,
              open: _open,
              enabled: isEnabled,
              size: widget.triggerSize,
              iconSize: widget.iconSize,
            );

        // No press transform on a menu trigger: the open menu is anchored
        // to this box, so scaling it drags the menu out from under the
        // pointer that is reaching for an item.
        return Tooltip(
          message: widget.tooltip,
          child: MouseRegion(
            cursor: isEnabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onTap: isEnabled ? _toggle : null,
              behavior: HitTestBehavior.opaque,
              child: trigger,
            ),
          ),
        );
      },
    );
  }
}

/// The menu glyph: quiet at rest, filled under the pointer, teal while
/// its menu is open.
class _MenuIcon extends StatefulWidget {
  const _MenuIcon({
    required this.icon,
    required this.open,
    required this.enabled,
    required this.size,
    required this.iconSize,
  });

  final List<List<dynamic>> icon;
  final bool open;
  final bool enabled;
  final double size;
  final double iconSize;

  @override
  State<_MenuIcon> createState() => _MenuIconState();
}

class _MenuIconState extends State<_MenuIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final tinted = widget.open || (_hovered && widget.enabled);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.open
              ? (tokens.isDark
                    ? LingoDeskColors.brandTealDeep
                    : LingoDeskColors.brandTealSoft)
              : tinted
              ? tokens.active
              : Colors.transparent,
          borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
        ),
        child: AnimatedTint(
          color: !widget.enabled
              ? tokens.muted.withValues(alpha: 0.4)
              : widget.open
              ? LingoDeskColors.brandTeal
              : tokens.foreground.withValues(alpha: _hovered ? 1 : 0.75),
          duration: LingoDeskMotion.fast,
          builder: (context, tint) =>
              LingoDeskIcon(widget.icon, size: widget.iconSize, color: tint),
        ),
      ),
    );
  }
}
