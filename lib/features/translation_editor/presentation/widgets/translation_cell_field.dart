import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
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
///
/// Because the write is debounced there is no button to press and no
/// spinner to watch, so a green ring blooms and fades once the value
/// reaches the bloc — the only signal that the edit was kept.
class TranslationCellField extends StatefulWidget {
  const TranslationCellField({
    super.key,
    required this.value,
    required this.highlightMissing,
    required this.onChanged,
    this.onAiTranslate,
    this.isTranslating = false,
  });

  final String value;

  /// Highlights the cell when it is empty (missing translation).
  final bool highlightMissing;

  final ValueChanged<String> onChanged;

  /// Fills this one cell from the AI provider. Null on the source column and
  /// whenever there is no source text to translate from.
  final VoidCallback? onAiTranslate;

  /// True while this cell is part of a running AI batch.
  final bool isTranslating;

  @override
  State<TranslationCellField> createState() => _TranslationCellFieldState();
}

class _TranslationCellFieldState extends State<TranslationCellField>
    with SingleTickerProviderStateMixin {
  static const _debounce = Duration(milliseconds: 400);
  static const _height = 36.0;

  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  /// Runs 1 -> 0 once per save; drives the confirmation ring's fade.
  late final AnimationController _saved = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 0,
  );

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
    _saved.dispose();
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
      _saved.reverse(from: 1);
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
      child: AnimatedBuilder(
        animation: _saved,
        builder: (context, child) {
          final glow = _saved.value;

          return AnimatedContainer(
            duration: LingoDeskMotion.fast,
            curve: LingoDeskMotion.curve,
            height: _height,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
              // Kept at a constant width so gaining focus never nudges the
              // text sideways.
              border: Border.all(
                color:
                    hasFocus ? LingoDeskColors.brandTeal : Colors.transparent,
              ),
              boxShadow:
                  glow == 0
                      ? null
                      : [
                        BoxShadow(
                          color: LingoDeskColors.complete.withValues(
                            alpha: 0.32 * glow,
                          ),
                          spreadRadius: 2 * glow,
                        ),
                      ],
            ),
            child: child,
          );
        },
        // Centre the field ourselves rather than leaning on
        // textAlignVertical: with isCollapsed the decorator has no slack to
        // align within, so the text silently rides against the top edge.
        // Center hands the TextField loose constraints, it takes its
        // intrinsic single-line height, and the leftover splits evenly.
        child: Padding(
          padding: const EdgeInsets.only(left: 9, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _handleChanged,
                    onSubmitted: (_) => _flush(),
                    maxLines: 1,
                    // The AI is mid-write; typing here would race the value
                    // that is about to land.
                    readOnly: widget.isTranslating,
                    cursorColor: LingoDeskColors.brandTeal,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.foreground,
                      fontSize: 13,
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText:
                          widget.isTranslating
                              ? 'Translating…'
                              : (showMissing ? 'Missing' : null),
                      hintStyle: TextStyle(
                        color:
                            widget.isTranslating
                                ? LingoDeskColors.brandTeal.withAlpha(190)
                                : LingoDeskColors.warning.withAlpha(170),
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
              _CellAiAction(
                onPressed: widget.onAiTranslate,
                isTranslating: widget.isTranslating,
                // An empty target cell keeps the affordance faintly visible
                // so it is findable without a mouse; a filled cell only
                // shows it under the pointer, where it can't distract.
                visible: _hovered || showMissing || widget.isTranslating,
                emphasized: showMissing,
                tokens: tokens,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The per-cell "translate this one" affordance.
///
/// Sits inside the cell rather than in the row menu because the single
/// missing field is the case you hit most often — it should be one click
/// from where you are already looking.
class _CellAiAction extends StatelessWidget {
  const _CellAiAction({
    required this.onPressed,
    required this.isTranslating,
    required this.visible,
    required this.emphasized,
    required this.tokens,
  });

  final VoidCallback? onPressed;
  final bool isTranslating;
  final bool visible;
  final bool emphasized;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (onPressed == null && !isTranslating) {
      return const SizedBox(width: 4);
    }

    return AnimatedOpacity(
      duration: LingoDeskMotion.fast,
      curve: LingoDeskMotion.curve,
      opacity: visible ? (emphasized && !isTranslating ? 0.75 : 1) : 0,
      child: SizedBox.square(
        dimension: 24,
        child:
            isTranslating
                ? const Padding(
                  padding: EdgeInsets.all(5),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LingoDeskColors.brandTeal,
                  ),
                )
                : IgnorePointer(
                  ignoring: !visible,
                  child: IconButton(
                    tooltip: 'Translate with AI',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                    onPressed: onPressed,
                    icon: LingoDeskIcon(
                      HugeIcons.strokeRoundedSparkles,
                      size: 15,
                      color:
                          emphasized
                              ? LingoDeskColors.warning
                              : LingoDeskColors.brandTeal,
                    ),
                  ),
                ),
      ),
    );
  }
}
