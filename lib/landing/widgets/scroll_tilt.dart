import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_motion.dart';
import 'reveal.dart';

/// Opens its child towards the viewer as it scrolls up into view and
/// closes it away again as it leaves out of the top, so the panel reads as
/// flat only while you can see all of it.
///
/// The two halves of the travel lean opposite ways: coming up from below
/// the fold the child is pitched one way and swings flat, and once it has
/// passed the middle of the window it keeps swinging the same way and
/// falls shut in the other direction. The result is a lid opening and
/// closing rather than a panel that stands up and stays there.
///
/// The tilt is glued to scroll position rather than played as an
/// animation: the driver is how much of the child is inside the viewport,
/// which means scrubbing the page backwards reopens it instead of leaving
/// a one-shot entrance behind.
///
/// Only the [Transform] rebuilds while scrolling — the child is passed
/// through [AnimatedBuilder], so a heavy subtree underneath is laid out
/// once and merely re-composited per frame.
class ScrollTilt extends StatefulWidget {
  const ScrollTilt({
    super.key,
    required this.child,
    this.maxTilt = 20,
    this.minScale = 0.93,
    this.perspective = 0.0011,
    this.flatAt = 0.82,
  });

  final Widget child;

  /// Degrees of rotation about the horizontal axis at each end of the
  /// travel. Opening (below the fold) leans towards the viewer, closing
  /// (past the middle of the window) leans the same amount away.
  final double maxTilt;

  /// Scale at either extreme of the tilt. Pitched panels read smaller, so
  /// easing the scale up alongside the rotation keeps the size steady.
  final double minScale;

  /// Matrix perspective entry. Larger is a shorter focal length and a
  /// more aggressive foreshortening.
  final double perspective;

  /// Visible fraction at which the child is considered "clearly visible"
  /// and stands fully upright. Below 1 so it finishes settling while
  /// comfortably in frame rather than at the exact moment it fits.
  final double flatAt;

  @override
  State<ScrollTilt> createState() => _ScrollTiltState();
}

class _ScrollTiltState extends State<ScrollTilt> {
  /// Signed lean: -1 fully open, 0 flat, 1 fully closed. A notifier
  /// rather than setState so scrolling repaints the transform without
  /// rebuilding the child.
  final ValueNotifier<double> _tilt = ValueNotifier<double>(-1);

  ScrollController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = LandingScroll.maybeOf(context);
    if (controller != _controller) {
      _controller?.removeListener(_update);
      _controller = controller?..addListener(_update);
    }
    // Whatever is already on screen at first paint never fires a scroll
    // notification, so it needs a measurement of its own.
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  void _update() {
    if (!mounted) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final viewport = MediaQuery.sizeOf(context).height;
    final height = box.size.height;
    if (viewport <= 0 || height <= 0) {
      return;
    }

    final top = box.localToGlobal(Offset.zero).dy;
    // How many of the child's own pixels are inside the viewport.
    final visible = (math.min(top + height, viewport) - math.max(top, 0.0))
        .clamp(0.0, height);
    // Measured against whichever is smaller: a panel taller than the
    // window can never be fully visible, and would otherwise never
    // reach flat.
    final reach = math.min(height, viewport) * widget.flatAt;
    final flat = (visible / reach).clamp(0.0, 1.0);

    // Visibility alone is symmetric — it cannot tell entering from
    // leaving — so the side of the window the child sits on decides which
    // way the same amount of lean points. The two agree at the crossover:
    // a child straddling the middle is at its most visible, so the sign
    // flips while the lean it applies to is still ~0.
    final closing = top + height / 2 < viewport / 2;
    _tilt.value = (1 - flat) * (closing ? 1 : -1);
  }

  @override
  void dispose() {
    _controller?.removeListener(_update);
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A perspective tilt is decoration, not information — reduced motion
    // gets the flat panel it is really after.
    if (!LingoDeskMotion.enabled(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _tilt,
      child: widget.child,
      builder: (context, child) {
        // Near-linear on purpose: an ease-out here would stand the panel
        // up in the first sliver of travel and read as a one-shot
        // entrance rather than something tied to the scrollbar. easeInOut
        // keeps the middle honest and only softens the two ends. Eased on
        // magnitude so opening and closing get the same shaped swing.
        final lean = _tilt.value;
        final eased =
            Curves.easeInOut.transform(lean.abs()) * (lean < 0 ? -1 : 1);
        final angle = eased * widget.maxTilt * math.pi / 180;
        final scale = lerpDouble(widget.minScale, 1, 1 - eased.abs())!;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, widget.perspective)
            ..rotateX(angle)
            ..scaleByDouble(scale, scale, 1, 1),
          child: child,
        );
      },
    );
  }
}
