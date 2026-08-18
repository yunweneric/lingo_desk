import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The smallest square a finger can reliably hit. Android's Material
/// guidance says 48, Apple's HIG says 44; taking the larger satisfies both.
const double kTouchTarget = 48;

/// The smallest square a pointer can reliably hit. Mice are precise, and
/// a desk tool packed with rows reads better when its controls are not
/// padded out to thumb size.
const double kPointerTarget = 32;

/// True on the platforms driven by a finger rather than a pointer.
///
/// Read off [defaultTargetPlatform] rather than `Platform.isAndroid`, so
/// the value is correct on web and under a platform override in tests.
bool get isTouchPlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// True where a pointer can hover, and so where revealing a control on
/// hover is a real affordance rather than a way to hide it forever.
bool get hasHover => !isTouchPlatform;

/// The side of the smallest square a control may occupy here.
double get minHitTarget => isTouchPlatform ? kTouchTarget : kPointerTarget;

/// [minHitTarget] as constraints, for `IconButton.constraints`.
BoxConstraints get hitTargetConstraints =>
    BoxConstraints.tightFor(width: minHitTarget, height: minHitTarget);

/// How opaque a control that is revealed on hover should be at rest.
///
/// Fully opaque without a pointer: on a touch screen there is no hover to
/// reveal it with, so a dimmed control is simply an undiscoverable one.
double restingOpacity(bool hovered) {
  if (!hasHover) {
    return 1;
  }
  return hovered ? 1 : 0.3;
}
