import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_field.dart';
import 'lingo_desk_icon.dart';
import 'lingo_desk_menu.dart';

/// One option in a [LingoDeskDropdown].
///
/// Everything past [value] and [label] is optional chrome: a leading
/// emoji (language flags), a leading icon, a second line of description
/// and a trailing mono tag (locale codes).
class LingoDeskDropdownItem<T> {
  const LingoDeskDropdownItem({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.leadingText,
    this.trailingText,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? description;
  final List<List<dynamic>>? icon;
  final String? leadingText;
  final String? trailingText;
  final bool enabled;
}

/// The app's dropdown.
///
/// Shares its border, fill, focus ring and size scale with
/// [LingoDeskTextField] via [lingoDeskFieldDecoration], and opens a
/// card-styled menu with hover, a selected tick and scrolling for long
/// lists instead of Material's default popup.
class LingoDeskDropdown<T> extends StatefulWidget {
  const LingoDeskDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    this.helperText,
    this.errorText,
    this.hintText = 'Select an option',
    this.icon,
    this.size = LingoDeskFieldSize.standard,
    this.enabled = true,
    this.expand = true,
    this.isRequired = false,
    this.monospace = false,
    this.menuMaxHeight = 320,
    this.menuWidth,
  });

  final List<LingoDeskDropdownItem<T>> items;
  final T? value;

  /// Null disables the control, matching Material's convention.
  final ValueChanged<T>? onChanged;

  final String? label;
  final String? description;
  final String? helperText;
  final String? errorText;
  final String hintText;

  /// Leading icon on the trigger, used when items carry no icon of their own.
  final List<List<dynamic>>? icon;

  final LingoDeskFieldSize size;
  final bool enabled;

  /// Fills the available width; false shrink-wraps (toolbars, table footers).
  final bool expand;

  final bool isRequired;

  /// Renders labels in the mono code style (page sizes, locale codes).
  final bool monospace;

  final double menuMaxHeight;

  /// Menu width; defaults to the trigger width when [expand] is true.
  final double? menuWidth;

  @override
  State<LingoDeskDropdown<T>> createState() => _LingoDeskDropdownState<T>();
}

class _LingoDeskDropdownState<T> extends State<LingoDeskDropdown<T>> {
  final _menuController = MenuController();
  bool _open = false;

  bool get _isEnabled =>
      widget.enabled && widget.onChanged != null && widget.items.isNotEmpty;

  LingoDeskDropdownItem<T>? get _selected {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

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

    return LingoDeskFieldScaffold(
      label: widget.label,
      description: widget.description,
      helperText: widget.helperText,
      errorText: widget.errorText,
      isRequired: widget.isRequired,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              widget.menuWidth ??
              (widget.expand && constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : 260.0);

          return MenuAnchor(
            controller: _menuController,
            alignmentOffset: const Offset(0, 6),
            onOpen: () => setState(() => _open = true),
            onClose: () => setState(() => _open = false),
            style: lingoDeskMenuStyle(tokens),
            menuChildren: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: width,
                  maxWidth: width < 320 ? 320 : width,
                  maxHeight: widget.menuMaxHeight,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in widget.items)
                        LingoDeskMenuTile(
                          label: item.label,
                          icon: item.icon,
                          leadingText: item.leadingText,
                          description: item.description,
                          trailingText: item.trailingText,
                          enabled: item.enabled,
                          selected: item.value == widget.value,
                          showSelection: true,
                          monospace: widget.monospace,
                          size: widget.size,
                          onPressed: () => widget.onChanged?.call(item.value),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            builder: (context, controller, child) => _DropdownTrigger(
              selected: _selected,
              hintText: widget.hintText,
              icon: widget.icon,
              size: widget.size,
              enabled: _isEnabled,
              open: _open,
              monospace: widget.monospace,
              hasError: widget.errorText != null,
              expand: widget.expand,
              onTap: _isEnabled ? _toggle : null,
            ),
          );
        },
      ),
    );
  }
}

class _DropdownTrigger<T> extends StatelessWidget {
  const _DropdownTrigger({
    required this.selected,
    required this.hintText,
    required this.icon,
    required this.size,
    required this.enabled,
    required this.open,
    required this.monospace,
    required this.hasError,
    required this.expand,
    required this.onTap,
  });

  final LingoDeskDropdownItem<T>? selected;
  final String hintText;
  final List<List<dynamic>>? icon;
  final LingoDeskFieldSize size;
  final bool enabled;
  final bool open;
  final bool monospace;
  final bool hasError;
  final bool expand;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final item = selected;
    final leadingIcon = item?.icon ?? icon;
    final labelStyle =
        (monospace
                ? LingoDeskTheme.codeStyle
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(
              fontSize: size.fontSize,
              color: !enabled
                  ? tokens.muted
                  : item == null
                  ? tokens.muted
                  : tokens.foreground,
              fontWeight: item == null ? FontWeight.w400 : FontWeight.w600,
            );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          height: size.height,
          padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
          decoration: lingoDeskFieldDecoration(
            tokens: tokens,
            size: size,
            focused: open,
            hasError: hasError,
            enabled: enabled,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (item?.leadingText != null) ...[
                Text(
                  item!.leadingText!,
                  style: TextStyle(fontSize: size.fontSize + 2),
                ),
                SizedBox(width: size.gap),
              ] else if (leadingIcon != null) ...[
                LingoDeskIcon(
                  leadingIcon,
                  size: size.iconSize,
                  color: open ? tokens.accent : tokens.muted,
                ),
                SizedBox(width: size.gap),
              ],
              // Expanded when the trigger fills its slot, so the chevron
              // is pinned to the right edge instead of trailing the label.
              _LabelSlot(
                expand: expand,
                child: Text(
                  item?.label ?? hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: labelStyle,
                ),
              ),
              if (item?.trailingText != null) ...[
                SizedBox(width: size.gap),
                Text(
                  item!.trailingText!,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.muted,
                    fontSize: size.fontSize - 2,
                  ),
                ),
              ],
              SizedBox(width: size.gap),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: LingoDeskIcon(
                  HugeIcons.strokeRoundedArrowDown01,
                  size: size.iconSize,
                  color: open ? tokens.accent : tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gives the trigger label all the leftover width when the dropdown fills
/// its slot, and only what it needs when the dropdown shrink-wraps.
class _LabelSlot extends StatelessWidget {
  const _LabelSlot({required this.expand, required this.child});

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return expand ? Expanded(child: child) : Flexible(child: child);
  }
}
