import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';

/// Plays a short fade-and-rise once, when the widget first mounts.
///
/// Used for content that arrives after a load — cards, table rows, tiles.
/// The [delay] is what turns a wall of cards into a sequence; prefer
/// [FadeSlideIn.staggered] over hand-rolled offsets so the rhythm is the
/// same everywhere.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = LingoDeskMotion.enterOffset,
    this.duration = LingoDeskMotion.slow,
  });

  /// Item [index] in a list, entering one [LingoDeskMotion.stagger] after
  /// the one before it.
  FadeSlideIn.staggered({
    super.key,
    required int index,
    required this.child,
    this.offset = LingoDeskMotion.enterOffset,
    this.duration = LingoDeskMotion.slow,
  }) : delay = LingoDeskMotion.delayFor(index);

  final Widget child;
  final Duration delay;

  /// Vertical distance travelled. Negative rises from below is the
  /// default; a positive value drops in from above.
  final double offset;

  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: LingoDeskMotion.entrance,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!LingoDeskMotion.enabled(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _animation.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Lifts a card a couple of pixels and drops a soft shadow under it while
/// the pointer is over it, and presses it back down on tap.
///
/// The shadow is drawn behind [child], so the child keeps painting its
/// own border and fill; [borderRadius] only has to match so the shadow
/// hugs the right silhouette.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = LingoDeskTheme.radius,
    this.lift = LingoDeskMotion.hoverLift,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final double lift;

  /// Set false to opt a single instance out without changing the tree.
  final bool enabled;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final active = widget.enabled && _hovered;
    // Pressing settles the card back onto the page rather than lifting it
    // further — the pointer is pushing it down.
    final dy = active && !_pressed ? -widget.lift : 0.0;
    final elevation = active && !_pressed ? 1.0 : 0.0;

    Widget content = AnimatedContainer(
      duration: LingoDeskMotion.standard,
      curve: LingoDeskMotion.curve,
      transform: Matrix4.translationValues(0, dy, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: (tokens.isDark ? 0.34 : 0.08) * elevation,
            ),
            blurRadius: 16 * elevation,
            offset: Offset(0, 5 * elevation),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: content,
    );
  }
}

/// Counts up to [value] instead of snapping to it.
///
/// Rebuilding with a new value continues from wherever the last one
/// stopped, so a stat that changes after an import rolls to its new
/// figure rather than flickering.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    this.style,
    this.duration = LingoDeskMotion.slow,
    this.maxLines,
    this.overflow,
  });

  final num value;
  final String suffix;
  final String prefix;
  final TextStyle? style;
  final Duration duration;
  final int? maxLines;
  final TextOverflow? overflow;

  String _format(num v) => '$prefix${v.round()}$suffix';

  @override
  Widget build(BuildContext context) {
    if (!LingoDeskMotion.enabled(context)) {
      return Text(
        _format(value),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: LingoDeskMotion.entrance,
      builder: (context, animated, _) {
        return Text(
          _format(animated),
          style: style,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// Cross-fades between colours for widgets that take a plain [Color]
/// rather than a decoration — icons, mostly.
class AnimatedTint extends StatelessWidget {
  const AnimatedTint({
    super.key,
    required this.color,
    required this.builder,
    this.duration = LingoDeskMotion.fast,
  });

  final Color color;
  final Widget Function(BuildContext context, Color color) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: duration,
      curve: LingoDeskMotion.curve,
      builder: (context, tinted, _) => builder(context, tinted ?? color),
    );
  }
}

/// Top-aligned replacement for [AnimatedSwitcher.defaultLayoutBuilder].
///
/// The default stacks the entering and leaving children centred, which
/// pins a shrink-wrapped scroll view to the middle of the page. Page
/// bodies that cross-fade between a spinner and their content pass this
/// so the content stays under the header while it swaps.
Widget topAlignedSwitcherLayout(
  Widget? currentChild,
  List<Widget> previousChildren,
) {
  return Stack(
    alignment: Alignment.topCenter,
    children: <Widget>[
      ...previousChildren,
      if (currentChild != null) currentChild,
    ],
  );
}
