import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_field.dart';
import 'lingo_desk_icon.dart';

/// The app's text input.
///
/// Draws its own chrome instead of leaning on [InputDecoration] so the
/// border, fill, focus ring and sizing match [LingoDeskDropdown] exactly.
/// Handles the patterns the app kept re-implementing: a leading icon, a
/// clear button, a monospace variant for keys, and commit-on-blur.
class LingoDeskTextField extends StatefulWidget {
  const LingoDeskTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.description,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.size = LingoDeskFieldSize.standard,
    this.enabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.clearable = false,
    this.monospace = false,
    this.isRequired = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onSubmitted,
    this.onFocusLost,
    this.onCleared,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? description;
  final String? hintText;
  final String? helperText;
  final String? errorText;

  /// HugeIcons stroke data drawn before the text.
  final List<List<dynamic>>? prefixIcon;

  /// Trailing widget; sits after the clear button when both are present.
  final Widget? suffix;

  final LingoDeskFieldSize size;
  final bool enabled;
  final bool autofocus;
  final bool obscureText;

  /// Shows a clear button once the field has text.
  final bool clearable;

  /// Renders the value in the mono code style (translation keys, codes).
  final bool monospace;

  final bool isRequired;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Fires when focus leaves the field — the commit-on-blur hook.
  final ValueChanged<String>? onFocusLost;

  final VoidCallback? onCleared;

  @override
  State<LingoDeskTextField> createState() => _LingoDeskTextFieldState();
}

class _LingoDeskTextFieldState extends State<LingoDeskTextField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  bool get _ownsController => widget.controller == null;
  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onFocusLost?.call(_controller.text);
    }
    setState(() => _focused = _focusNode.hasFocus);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final size = widget.size;
    final isMultiline = widget.maxLines != 1;
    final baseStyle = widget.monospace
        ? LingoDeskTheme.codeStyle.copyWith(fontSize: size.fontSize)
        : Theme.of(context).textTheme.bodyMedium;
    final textStyle = baseStyle?.copyWith(
      fontSize: size.fontSize,
      color: widget.enabled ? tokens.foreground : tokens.muted,
    );

    final field = TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,
      style: textStyle,
      cursorColor: tokens.accent,
      cursorWidth: 1.6,
      cursorRadius: const Radius.circular(2),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        counterText: '',
        hintText: widget.hintText,
        hintStyle: textStyle?.copyWith(
          color: tokens.muted,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    final content = Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[
          LingoDeskIcon(
            widget.prefixIcon!,
            size: size.iconSize,
            color: _focused ? tokens.accent : tokens.muted,
          ),
          SizedBox(width: size.gap),
        ],
        Expanded(child: field),
        if (widget.clearable)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              if (value.text.isEmpty || !widget.enabled) {
                return const SizedBox.shrink();
              }
              return _FieldIconButton(
                icon: HugeIcons.strokeRoundedCancel01,
                tooltip: 'Clear',
                size: size,
                color: tokens.muted,
                onPressed: _clear,
              );
            },
          ),
        if (widget.suffix != null) ...[
          SizedBox(width: size.gap),
          widget.suffix!,
        ],
      ],
    );

    return LingoDeskFieldScaffold(
      label: widget.label,
      description: widget.description,
      helperText: widget.helperText,
      errorText: widget.errorText,
      isRequired: widget.isRequired,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        height: isMultiline ? null : size.height,
        padding: EdgeInsets.symmetric(
          horizontal: size.horizontalPadding,
          vertical: isMultiline ? 12 : 0,
        ),
        decoration: lingoDeskFieldDecoration(
          tokens: tokens,
          size: size,
          focused: _focused,
          hasError: widget.errorText != null,
          enabled: widget.enabled,
        ),
        child: content,
      ),
    );
  }
}

/// Small square icon affordance sized to sit inside a field.
class _FieldIconButton extends StatelessWidget {
  const _FieldIconButton({
    required this.icon,
    required this.tooltip,
    required this.size,
    required this.color,
    required this.onPressed,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final LingoDeskFieldSize size;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: LingoDeskIcon(icon, size: size.iconSize - 2, color: color),
        ),
      ),
    );
  }
}
