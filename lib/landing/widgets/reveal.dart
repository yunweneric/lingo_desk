import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_motion.dart';

/// Hands the page's [ScrollController] down to every [Reveal] below it,
/// so entrances can be driven by scroll position without each one owning
/// a listener on a controller it has no reference to.
class LandingScroll extends InheritedWidget {
  const LandingScroll({
    super.key,
    required this.controller,
    required super.child,
  });

  final ScrollController controller;

  static ScrollController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LandingScroll>()?.controller;

  @override
  bool updateShouldNotify(LandingScroll oldWidget) =>
      oldWidget.controller != controller;
}

/// Fades and lifts its child in the first time it scrolls into view, then
/// stops listening — an entrance, not an effect that replays.
///
/// [index] staggers siblings through [LingoDeskMotion.delayFor], and the
/// whole thing collapses to its end state when the platform asks for
/// reduced motion.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  ScrollController? _controller;
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = LandingScroll.maybeOf(context);
    if (controller == _controller) {
      return;
    }
    _controller?.removeListener(_check);
    _controller = controller?..addListener(_check);
    // The sections already on screen at first paint never fire a scroll
    // notification, so they need a check of their own.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (_shown || !mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final top = box.localToGlobal(Offset.zero).dy;
    // Trip a little before the element reaches the fold, so it has
    // finished arriving by the time it is properly in view.
    if (top < MediaQuery.sizeOf(context).height * 0.92) {
      _controller?.removeListener(_check);
      setState(() => _shown = true);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!LingoDeskMotion.enabled(context)) {
      return widget.child;
    }
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.045),
      duration: LingoDeskMotion.slow,
      curve: LingoDeskMotion.entrance,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: LingoDeskMotion.slow,
        curve: LingoDeskMotion.entrance,
        child: widget.child,
      ),
    );
  }
}

/// A [Reveal] whose delay follows its position in a row or grid.
class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!LingoDeskMotion.enabled(context)) {
      return child;
    }
    return Reveal(
      index: index,
      child: _DelayedFade(delay: LingoDeskMotion.delayFor(index), child: child),
    );
  }
}

/// Holds a child back briefly so siblings arrive one after another.
class _DelayedFade extends StatefulWidget {
  const _DelayedFade({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_DelayedFade> createState() => _DelayedFadeState();
}

class _DelayedFadeState extends State<_DelayedFade> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _ready ? 1 : 0,
      duration: LingoDeskMotion.standard,
      curve: LingoDeskMotion.curve,
      child: widget.child,
    );
  }
}
