import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';

/// Editable translation cell.
///
/// Keeps its own controller so typing is instant, and debounces
/// [onChanged] so the bloc persists after the user pauses.
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

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _lastSent = '';

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

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color:
            showMissing
                ? LingoDeskColors.warning.withAlpha(tokens.isDark ? 46 : 26)
                : tokens.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              _focusNode.hasFocus
                  ? LingoDeskColors.brandTeal
                  : showMissing
                  ? LingoDeskColors.warning.withAlpha(120)
                  : tokens.border,
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _handleChanged,
        onSubmitted: (_) => _flush(),
        maxLines: 1,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.foreground,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: showMissing ? 'Missing' : null,
          hintStyle: TextStyle(
            color: LingoDeskColors.warning.withAlpha(190),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}
