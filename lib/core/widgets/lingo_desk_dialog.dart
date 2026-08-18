import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../responsive/breakpoints.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_icon.dart';

/// Horizontal inset an [AlertDialog] keeps between itself and the window,
/// per side, plus the padding its content sits in.
const double _dialogChrome = 112;

/// The width a dialog can actually take here.
///
/// [preferred] is what the form was designed for; the return value is that
/// width clamped to what the window has left once the dialog's own inset
/// and content padding are paid for. Without this a 560px form simply
/// overflows a 375pt phone.
double responsiveDialogWidth(
  BuildContext context, {
  required double preferred,
  double min = 280,
}) {
  final available = MediaQuery.sizeOf(context).width - _dialogChrome;
  return math.max(min, math.min(preferred, available));
}

/// A dialog that takes the shape the window can carry.
///
/// On anything wider than a phone it is the ordinary centred [AlertDialog]
/// the app has always used, sized to [preferredWidth] but never wider than
/// the window. On a phone it becomes a full-screen sheet: a form squeezed
/// into a 295px card with the keyboard up is a form nobody can fill in.
class LingoDeskDialog extends StatelessWidget {
  const LingoDeskDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.preferredWidth = 460,
    this.scrollable = false,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  /// The width the form was designed for, honoured when there is room.
  final double preferredWidth;

  /// Whether the body needs a scroll view of its own. Leave false for
  /// content that already manages its own scrolling with a [Flexible]
  /// child — wrapping that a second time unbounds it.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (context.windowSize.isCompact) {
      return _FullScreen(
        title: title,
        actions: actions,
        scrollable: scrollable,
        child: content,
      );
    }

    return AlertDialog(
      title: title,
      content: SizedBox(
        width: responsiveDialogWidth(context, preferred: preferredWidth),
        child: content,
      ),
      scrollable: scrollable,
      actions: actions,
    );
  }
}

/// The phone form: title bar with a close button, the body filling what is
/// left, and the actions pinned to the bottom above the keyboard.
class _FullScreen extends StatelessWidget {
  const _FullScreen({
    required this.title,
    required this.actions,
    required this.scrollable,
    required this.child,
  });

  final Widget title;
  final List<Widget> actions;
  final bool scrollable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    // What the soft keyboard is covering. The action bar rides above it
    // so the confirm button never ends up under the keys.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog.fullscreen(
      backgroundColor: tokens.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: LingoDeskIcon(
                        HugeIcons.strokeRoundedCancel01,
                        color: tokens.foreground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: title,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: child,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: child,
                    ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + keyboardInset),
                child: _ActionBar(actions: actions),
              ),
          ],
        ),
      ),
    );
  }
}

/// The actions across the foot of a full-screen dialog.
///
/// Laid out edge to edge rather than huddled at the right: on a phone the
/// bottom of the screen is the whole width of a thumb's reach, and a
/// stretched row of buttons is easier to hit than a right-aligned cluster.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.length == 1) {
      return actions.single;
    }

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index != 0) const SizedBox(width: 8),
          Expanded(child: actions[index]),
        ],
      ],
    );
  }
}
