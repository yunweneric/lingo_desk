import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_icon.dart';

/// Size scale shared by every LingoDesk form control.
///
/// `compact` is for table/toolbar chrome, `standard` matches the 42px
/// toolbar buttons, `large` is the form-and-dialog size.
enum LingoDeskFieldSize { compact, standard, large }

extension LingoDeskFieldMetrics on LingoDeskFieldSize {
  double get height => switch (this) {
    LingoDeskFieldSize.compact => 34,
    LingoDeskFieldSize.standard => 42,
    LingoDeskFieldSize.large => 50,
  };

  double get fontSize => switch (this) {
    LingoDeskFieldSize.compact => 12,
    LingoDeskFieldSize.standard => 14,
    LingoDeskFieldSize.large => 15,
  };

  double get horizontalPadding => switch (this) {
    LingoDeskFieldSize.compact => 10,
    LingoDeskFieldSize.standard => 12,
    LingoDeskFieldSize.large => 14,
  };

  double get iconSize => switch (this) {
    LingoDeskFieldSize.compact => 15,
    LingoDeskFieldSize.standard => 18,
    LingoDeskFieldSize.large => 19,
  };

  /// Gap between the leading icon and the content.
  double get gap => switch (this) {
    LingoDeskFieldSize.compact => 7,
    LingoDeskFieldSize.standard => 9,
    LingoDeskFieldSize.large => 10,
  };

  double get radius => switch (this) {
    LingoDeskFieldSize.compact => LingoDeskTheme.radiusSm,
    _ => LingoDeskTheme.radius,
  };
}

/// The one border/fill recipe every field draws, so a text input and a
/// dropdown sitting next to each other are indistinguishable at rest.
///
/// Focus is a teal 1.5px border plus a soft ring; error swaps the same
/// treatment to red; disabled drops to the muted surface.
BoxDecoration lingoDeskFieldDecoration({
  required LingoDeskTokens tokens,
  required LingoDeskFieldSize size,
  bool focused = false,
  bool hasError = false,
  bool enabled = true,
}) {
  final accent = hasError ? LingoDeskColors.error : LingoDeskColors.brandTeal;
  final highlighted = enabled && (focused || hasError);

  return BoxDecoration(
    color: enabled
        ? tokens.card
        : (tokens.isDark
              ? Colors.white.withValues(alpha: 0.04)
              : LingoDeskColors.surface),
    borderRadius: BorderRadius.circular(size.radius),
    border: Border.all(
      color: highlighted ? accent : tokens.border,
      width: highlighted ? 1.5 : 1,
    ),
    boxShadow: enabled && focused
        ? [
            BoxShadow(
              color: accent.withValues(alpha: tokens.isDark ? 0.24 : 0.14),
              spreadRadius: 3,
            ),
          ]
        : null,
  );
}

/// Inline validation message with the alert icon used across the app.
class LingoDeskFieldError extends StatelessWidget {
  const LingoDeskFieldError({super.key, required this.message, this.size = 18});

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LingoDeskIcon(
          HugeIcons.strokeRoundedAlertCircle,
          size: size,
          color: LingoDeskColors.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: LingoDeskColors.error),
          ),
        ),
      ],
    );
  }
}

/// Label + description + control + helper/error stack.
///
/// Both [LingoDeskTextField] and [LingoDeskDropdown] wrap their control in
/// this, so labelling and spacing never drift between the two.
class LingoDeskFieldScaffold extends StatelessWidget {
  const LingoDeskFieldScaffold({
    super.key,
    required this.child,
    this.label,
    this.description,
    this.helperText,
    this.errorText,
    this.trailing,
    this.isRequired = false,
  });

  final Widget child;

  /// Bold label above the control.
  final String? label;

  /// Small muted line between the label and the control.
  final String? description;

  /// Small muted line below the control; hidden while [errorText] shows.
  final String? helperText;

  /// Red validation message below the control.
  final String? errorText;

  /// Optional widget pinned to the right of the label row.
  final Widget? trailing;

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodyMedium?.copyWith(
      color: tokens.muted,
      fontSize: 12,
    );

    if (label == null &&
        description == null &&
        helperText == null &&
        errorText == null) {
      return child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(label!, style: theme.textTheme.labelLarge),
              if (isRequired)
                Text(
                  ' *',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: LingoDeskColors.error,
                  ),
                ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          SizedBox(height: description == null ? 8 : 6),
        ],
        if (description != null) ...[
          Text(description!, style: captionStyle),
          const SizedBox(height: 10),
        ],
        child,
        if (errorText != null) ...[
          const SizedBox(height: 8),
          LingoDeskFieldError(message: errorText!),
        ] else if (helperText != null) ...[
          const SizedBox(height: 8),
          Text(helperText!, style: captionStyle),
        ],
      ],
    );
  }
}
