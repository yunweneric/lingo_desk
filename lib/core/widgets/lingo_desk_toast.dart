import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_icon.dart';

/// One message on its way to the toast stack.
///
/// Compared by identity, so re-emitting the same text from a bloc always
/// counts as a new notice and shows again.
@immutable
class ToastNotice {
  const ToastNotice(
    this.message, {
    this.status = LingoDeskStatus.neutral,
    this.title,
    this.duration,
    this.actionLabel,
    this.onAction,
  });

  const ToastNotice.success(
    this.message, {
    this.title,
    this.duration,
    this.actionLabel,
    this.onAction,
  }) : status = LingoDeskStatus.success;

  const ToastNotice.error(
    this.message, {
    this.title,
    this.duration,
    this.actionLabel,
    this.onAction,
  }) : status = LingoDeskStatus.error;

  const ToastNotice.warning(
    this.message, {
    this.title,
    this.duration,
    this.actionLabel,
    this.onAction,
  }) : status = LingoDeskStatus.warning;

  const ToastNotice.info(
    this.message, {
    this.title,
    this.duration,
    this.actionLabel,
    this.onAction,
  }) : status = LingoDeskStatus.info;

  final String message;

  /// Optional bold first line. Without it the message itself is set in
  /// semibold and carries the toast on its own.
  final String? title;

  final LingoDeskStatus status;

  /// Overrides [lifetime]; mostly useful for a toast that must outlast a
  /// long-running action.
  final Duration? duration;

  final String? actionLabel;
  final VoidCallback? onAction;

  /// How long the toast stays before it retires itself.
  ///
  /// Failures sit long enough to be read twice, since they usually name a
  /// path or a provider error the user has to act on.
  Duration get lifetime =>
      duration ??
      switch (status) {
        LingoDeskStatus.error => const Duration(seconds: 7),
        LingoDeskStatus.warning => const Duration(seconds: 5),
        _ => const Duration(seconds: 4),
      };
}

/// A toast the stack is currently showing.
class _LiveToast {
  _LiveToast(this.id, this.notice);

  final int id;
  final ToastNotice notice;

  /// Set when something asks the toast to leave before its time is up.
  /// The card watches this, plays its exit, then retires itself — which
  /// is why dismissal is a flag here rather than a straight list removal.
  bool retiring = false;
}

/// Owns the toast stack.
///
/// Reach it with `context.toaster`, or — almost always — just call one of
/// the `context.showXToast(...)` helpers.
class LingoDeskToastController extends ChangeNotifier {
  /// Past this many on screen, the oldest starts leaving as the next
  /// arrives, so a burst of failures can't bury the page.
  static const maxVisible = 4;

  final List<_LiveToast> _toasts = <_LiveToast>[];
  int _nextId = 0;

  /// Oldest first — the stack renders top-down in arrival order. Library
  /// private: the public surface is [show], [dismiss] and [dismissAll].
  List<_LiveToast> get _visible => List.unmodifiable(_toasts);

  /// Whether anything is on screen right now.
  bool get isEmpty => _toasts.isEmpty;

  /// Shows [notice] and returns its id, for a later [dismiss].
  int show(ToastNotice notice) {
    final live = _LiveToast(_nextId++, notice);
    _toasts.add(live);

    final staying = _toasts.where((toast) => !toast.retiring).toList();
    if (staying.length > maxVisible) {
      staying.first.retiring = true;
    }

    notifyListeners();
    return live.id;
  }

  /// Asks one toast to play its exit and go.
  void dismiss(int id) {
    for (final toast in _toasts) {
      if (toast.id == id && !toast.retiring) {
        toast.retiring = true;
        notifyListeners();
        return;
      }
    }
  }

  void dismissAll() {
    var changed = false;
    for (final toast in _toasts) {
      if (!toast.retiring) {
        toast.retiring = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Called by a card once its exit has finished playing.
  void _retire(int id) {
    final before = _toasts.length;
    _toasts.removeWhere((toast) => toast.id == id);
    if (_toasts.length != before) {
      notifyListeners();
    }
  }
}

class _ToastScope extends InheritedWidget {
  const _ToastScope({required this.controller, required super.child});

  final LingoDeskToastController controller;

  @override
  bool updateShouldNotify(_ToastScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Hosts the toast stack above the entire app.
///
/// Installed from [MaterialApp.builder] so toasts outlive route changes
/// and paint over dialogs — a save that fails while a modal is open still
/// gets to say so. Anchored top-right, which is where a desktop app puts
/// transient feedback; the bottom of the window belongs to the content.
class LingoDeskToastHost extends StatefulWidget {
  const LingoDeskToastHost({super.key, required this.child});

  final Widget child;

  static LingoDeskToastController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'No LingoDeskToastHost above this context — wrap the app with it in '
      'core/app.dart before calling showToast.',
    );
    return controller!;
  }

  /// Reads the controller without registering a dependency, so it is safe
  /// from bloc listeners and other callbacks that run outside a build.
  static LingoDeskToastController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ToastScope>()?.controller;

  @override
  State<LingoDeskToastHost> createState() => _LingoDeskToastHostState();
}

class _LingoDeskToastHostState extends State<LingoDeskToastHost> {
  final LingoDeskToastController _controller = LingoDeskToastController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ToastScope(
      controller: _controller,
      child: Stack(
        children: [
          widget.child,
          // Anchored rather than full-bleed: the stack only ever occupies
          // the space its cards need, so the rest of the window keeps
          // taking clicks while a toast is up.
          Positioned(
            top: 0,
            right: 0,
            child: _ToastStack(controller: _controller),
          ),
        ],
      ),
    );
  }
}

class _ToastStack extends StatelessWidget {
  const _ToastStack({required this.controller});

  final LingoDeskToastController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final toasts = controller._visible;
        if (toasts.isEmpty) {
          // Nothing rendered means nothing to hit-test in the corner.
          return const SizedBox.shrink();
        }

        // Narrow windows get narrower toasts rather than a card that runs
        // off the edge of the pane.
        final available = MediaQuery.sizeOf(context).width - 40;
        final maxWidth = math.max(200.0, math.min(380.0, available));

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            // Buttons and text inside the cards need a Material ancestor;
            // the app's own Material sits below us in the tree.
            child: Material(
              type: MaterialType.transparency,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minWidth: math.min(300.0, maxWidth),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final live in toasts)
                      _ToastCard(
                        key: ValueKey<int>(live.id),
                        live: live,
                        onRetired: () => controller._retire(live.id),
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

class _ToastCard extends StatefulWidget {
  const _ToastCard({super.key, required this.live, required this.onRetired});

  final _LiveToast live;
  final VoidCallback onRetired;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> with TickerProviderStateMixin {
  /// Entrance and exit. Reversing it plays the exit, and the card removes
  /// itself from the stack once that finishes.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: LingoDeskMotion.standard,
  )..forward();

  /// Counts the toast's time down, and drives the bar along its bottom
  /// edge. [AnimationBehavior.preserve] so that "reduce motion" shortens
  /// the animations, not the seconds the message stays readable.
  late final AnimationController _lifetime = AnimationController(
    vsync: this,
    duration: widget.live.notice.lifetime,
    animationBehavior: AnimationBehavior.preserve,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _reveal,
    curve: LingoDeskMotion.entrance,
    reverseCurve: LingoDeskMotion.curve,
  );

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _lifetime
      ..addStatusListener(_onLifetimeDone)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant _ToastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.live.retiring) {
      _leave();
    }
  }

  @override
  void dispose() {
    _lifetime.removeStatusListener(_onLifetimeDone);
    _lifetime.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _onLifetimeDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _leave();
    }
  }

  void _leave() {
    if (_leaving) {
      return;
    }
    _leaving = true;
    _lifetime.stop();
    _reveal.reverse().whenComplete(() {
      if (mounted) {
        widget.onRetired();
      }
    });
  }

  /// Hovering holds the toast open — on desktop the pointer is already
  /// over the corner, and a message shouldn't expire while it is being
  /// read or aimed at.
  void _setHovered(bool hovered) {
    if (_leaving) {
      return;
    }
    if (hovered) {
      _lifetime.stop();
    } else {
      _lifetime.forward();
    }
  }

  void _runAction() {
    widget.live.notice.onAction?.call();
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final notice = widget.live.notice;
    final style = LingoDeskStatusStyle.resolve(tokens, notice.status);
    final text = Theme.of(context).textTheme;
    final hasTitle = notice.title != null;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(color: style.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: tokens.isDark ? 0.5 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        // Clips the lifetime bar into the bottom corners.
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: LingoDeskIcon(
                      _iconFor(notice.status),
                      size: 20,
                      color: style.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTitle) ...[
                          Text(
                            notice.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge?.copyWith(
                              color: style.foreground,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text(
                          notice.message,
                          // Provider errors can run long; a toast that
                          // fills the window is worse than a clipped one.
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            // Without a title the message is the headline
                            // and carries the weight itself.
                            color: hasTitle ? tokens.muted : style.foreground,
                            fontWeight: hasTitle
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                        if (notice.actionLabel != null) ...[
                          const SizedBox(height: 6),
                          _ToastAction(
                            label: notice.actionLabel!,
                            color: style.accent,
                            onPressed: _runAction,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _ToastCloseButton(color: tokens.muted, onPressed: _leave),
                ],
              ),
            ),
            _LifetimeBar(animation: _lifetime, color: style.accent),
          ],
        ),
      ),
    );

    Widget content = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      // Opaque so a click lands on the toast instead of falling through to
      // whatever it is covering; clicking the body is also how you flick a
      // toast away without aiming at the close button.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: card,
      ),
    );

    if (LingoDeskMotion.enabled(context)) {
      content = AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(24 * (1 - _curve.value), 0),
            child: child,
          );
        },
        child: content,
      );
    }

    // Collapsing the height on the way out is what lets the toasts below
    // slide up instead of jumping when one in the middle goes.
    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _curve,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: content,
        ),
      ),
    );
  }
}

/// The bar along the bottom edge, draining left to right as the toast's
/// time runs out — and visibly stopping while the pointer rests on it.
class _LifetimeBar extends StatelessWidget {
  const _LifetimeBar({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: (1 - animation.value).clamp(0.0, 1.0),
              child: ColoredBox(color: color.withValues(alpha: 0.5)),
            ),
          );
        },
      ),
    );
  }
}

class _ToastAction extends StatelessWidget {
  const _ToastAction({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
        ),
      ),
      child: Text(label),
    );
  }
}

/// Deliberately not an [IconButton] with a `tooltip`: the toast stack
/// lives above the Navigator so it can paint over dialogs, which means
/// there is no [Overlay] in scope for a tooltip to mount into. The hover
/// tint does the affordance work instead, and the label is exposed to
/// screen readers through [Semantics].
class _ToastCloseButton extends StatefulWidget {
  const _ToastCloseButton({required this.color, required this.onPressed});

  final Color color;
  final VoidCallback onPressed;

  @override
  State<_ToastCloseButton> createState() => _ToastCloseButtonState();
}

class _ToastCloseButtonState extends State<_ToastCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Semantics(
      label: 'Dismiss',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: LingoDeskMotion.fast,
            curve: LingoDeskMotion.curve,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _hovered
                  ? (tokens.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
            ),
            child: Center(
              child: LingoDeskIcon(
                HugeIcons.strokeRoundedCancel01,
                size: 15,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<List<dynamic>> _iconFor(LingoDeskStatus status) {
  return switch (status) {
    LingoDeskStatus.success => HugeIcons.strokeRoundedCheckmarkCircle02,
    LingoDeskStatus.error => HugeIcons.strokeRoundedCancelCircle,
    LingoDeskStatus.warning => HugeIcons.strokeRoundedAlert02,
    LingoDeskStatus.info => HugeIcons.strokeRoundedInformationCircle,
    LingoDeskStatus.neutral => HugeIcons.strokeRoundedInformationCircle,
  };
}

/// How the rest of the app talks to the toast stack.
extension LingoDeskToastX on BuildContext {
  LingoDeskToastController get toaster => LingoDeskToastHost.of(this);

  int showToast(ToastNotice notice) => LingoDeskToastHost.of(this).show(notice);

  /// An action landed: saved, created, deleted, exported.
  int showSuccessToast(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) => showToast(
    ToastNotice.success(
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );

  /// An action failed and the user's work did not happen.
  int showErrorToast(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) => showToast(
    ToastNotice.error(
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );

  /// It went through, but not cleanly — a partial run, or a precondition
  /// the user needs to fix before trying again.
  int showWarningToast(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) => showToast(
    ToastNotice.warning(
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );

  /// Neither good nor bad: a cancel, a no-op, something worth knowing.
  int showInfoToast(
    String message, {
    String? title,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) => showToast(
    ToastNotice.info(
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
}
