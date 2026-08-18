import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_icon.dart';

/// The app's checkbox: a circle that fills with the brand colour and
/// stamps a tick into it.
///
/// Round rather than square, so it reads as one family with the radios
/// and the selection dots elsewhere in the app. Three things move on
/// toggle and nothing else does: the fill grows out of the centre, the
/// tick scales in behind it, and the ring warms under the pointer. A
/// null [onChanged] disables it — the box stays visible at half strength
/// rather than disappearing, because a row it belongs to still has to
/// show what state it is in.
class LingoDeskCheckbox extends StatefulWidget {
  const LingoDeskCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 20,
    this.padding = const EdgeInsets.all(6),
    this.semanticLabel,
  });

  final bool value;

  /// Null disables the box.
  final ValueChanged<bool>? onChanged;

  /// Diameter of the circle. The tick and ring scale with it.
  final double size;

  /// Tap target grown around the circle. Zero where the box is only
  /// being looked at and something else owns the tap.
  final EdgeInsetsGeometry padding;

  /// Read out in place of the box itself; give it the label of whatever
  /// the box is selecting when the box stands alone.
  final String? semanticLabel;

  @override
  State<LingoDeskCheckbox> createState() => _LingoDeskCheckboxState();
}

class _LingoDeskCheckboxState extends State<LingoDeskCheckbox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final enabled = widget.onChanged != null;
    final checked = widget.value;
    final size = widget.size;

    final fill = checked
        ? (enabled
              ? LingoDeskColors.brandTeal
              : LingoDeskColors.brandTeal.withValues(alpha: 0.4))
        : Colors.transparent;
    final border = checked
        ? fill
        : enabled && _hovered
        ? LingoDeskColors.brandTeal
        : tokens.border;

    final box = AnimatedContainer(
      duration: LingoDeskMotion.fast,
      curve: LingoDeskMotion.curve,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.4),
        // A halo instead of a border that thickens: the box keeps its
        // size, so a row of them never shifts when one is hovered.
        boxShadow: enabled && _hovered
            ? [
                BoxShadow(
                  color: LingoDeskColors.brandTeal.withValues(alpha: 0.16),
                  spreadRadius: size * 0.16,
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        scale: checked ? 1 : 0.4,
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        child: AnimatedOpacity(
          opacity: checked ? 1 : 0,
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          child: LingoDeskIcon(
            HugeIcons.strokeRoundedTick02,
            size: size * 0.66,
            color: Colors.white,
          ),
        ),
      ),
    );

    return Semantics(
      checked: checked,
      enabled: enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: enabled ? () => widget.onChanged!(!checked) : null,
          behavior: HitTestBehavior.opaque,
          // The box is 20px; the target around it is not.
          child: Padding(padding: widget.padding, child: box),
        ),
      ),
    );
  }
}

/// A [LingoDeskCheckbox] with its label, as one row that toggles.
///
/// Replaces `CheckboxListTile`, whose Material padding and ripple sit
/// outside this app's spacing. Selected rows are tinted rather than only
/// ticked, so a long list shows its selection down the left edge.
class LingoDeskCheckboxTile extends StatefulWidget {
  const LingoDeskCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.description,
    this.leading,
    this.trailing,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  final String title;

  /// Second line under [title] — a file name, a path, a count.
  final String? description;

  /// Emoji shown before the title, for a locale's flag.
  final String? leading;

  /// Aside pinned to the right of the row.
  final Widget? trailing;

  @override
  State<LingoDeskCheckboxTile> createState() => _LingoDeskCheckboxTileState();
}

class _LingoDeskCheckboxTileState extends State<LingoDeskCheckboxTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final enabled = widget.onChanged != null;
    final checked = widget.value;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? () => widget.onChanged!(!checked) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: checked
                ? LingoDeskColors.brandTeal.withValues(alpha: 0.08)
                : _hovered
                ? tokens.active.withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: checked
                  ? LingoDeskColors.brandTeal.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // The row owns the gesture, so the box only has to look
              // like the thing that was toggled.
              IgnorePointer(
                child: LingoDeskCheckbox(
                  value: checked,
                  onChanged: enabled ? (_) {} : null,
                ),
              ),
              const SizedBox(width: 4),
              if (widget.leading != null) ...[
                Text(widget.leading!, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: enabled ? tokens.foreground : tokens.muted,
                      ),
                    ),
                    if (widget.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LingoDeskTheme.codeStyle.copyWith(
                          color: tokens.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 10),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
