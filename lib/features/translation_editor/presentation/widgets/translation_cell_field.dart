import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';

/// Editable translation cell.
///
/// Keeps its own controller so typing is instant, and debounces
/// [onChanged] so the bloc persists after the user pauses.
///
/// Chrome is earned, not permanent: at rest the cell is just text on the
/// row. Hovering fills it faintly to say "this is editable", focus draws
/// the only real border on the row, and an empty target cell carries a
/// warm tint. A grid of outlined boxes reads as a form; this reads as a
/// document you can type into.
class TranslationCellField extends StatefulWidget {
  const TranslationCellField({
    super.key,
    required this.value,
    required this.highlightMissing,
    required this.onChanged,
  });

  final String value;

  /// Highlights the cell when it is empty (missing translation).
  final bool highlightMissing;

  final ValueChanged<String> onChanged;

  @override
  State<TranslationCellField> createState() => _TranslationCellFieldState();
}

class _TranslationCellFieldState extends State<TranslationCellField> {
  static const _debounce = Duration(milliseconds: 400);
  static const _height = 36.0;

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _lastSent = '';
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _lastSent = widget.value;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(TranslationCellField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external updates (imports, reloads) unless the user is typing.
    if (widget.value != oldWidget.value &&
        widget.value != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.value;
      _lastSent = widget.value;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _flush();
    }
    // Rebuild to update the focused border.
    setState(() {});
  }

  void _handleChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _flush);
  }

  void _flush() {
    _debounceTimer?.cancel();
    if (_controller.text != _lastSent) {
      _lastSent = _controller.text;
      widget.onChanged(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final isEmpty = _controller.text.trim().isEmpty;
    final showMissing = widget.highlightMissing && isEmpty;
    final hasFocus = _focusNode.hasFocus;

    final Color background;
    if (hasFocus) {
      background = tokens.card;
    } else if (showMissing) {
      background = LingoDeskColors.warning.withAlpha(tokens.isDark ? 38 : 22);
    } else if (_hovered) {
      background = tokens.active;
    } else {
      background = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: _height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
          // Kept at a constant width so gaining focus never nudges the
          // text sideways.
          border: Border.all(
            color: hasFocus ? LingoDeskColors.brandTeal : Colors.transparent,
          ),
        ),
        // isCollapsed strips the decorator's built-in minimums so the box
        // is exactly _height, leaving real slack for textAlignVertical to
        // centre into. The line height is pinned too: the theme's 1.45
        // body leading plus padding overflows this box, and an
        // over-constrained field silently rides high instead of centring.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _handleChanged,
            onSubmitted: (_) => _flush(),
            maxLines: 1,
            cursorColor: LingoDeskColors.brandTeal,
            textAlignVertical: TextAlignVertical.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.foreground,
              fontSize: 13,
              height: 1.2,
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: showMissing ? 'Missing' : null,
              hintStyle: TextStyle(
                color: LingoDeskColors.warning.withAlpha(170),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
