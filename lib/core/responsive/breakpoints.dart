import 'package:flutter/widgets.dart';

/// The width bands every layout in the app is designed against.
///
/// These are Material 3's window size classes. Using the published scale
/// rather than a set of home-grown numbers means the boundaries already
/// line up with real hardware: a phone in portrait is compact, the same
/// phone in landscape is medium, a tablet in landscape is expanded, and a
/// desktop window is large or wider.
enum WindowSizeClass {
  /// < 600 — phones in portrait.
  compact(0),

  /// 600–839 — phones in landscape, small tablets in portrait.
  medium(600),

  /// 840–1199 — tablets in landscape, small desktop windows.
  expanded(840),

  /// 1200–1599 — desktop.
  large(1200),

  /// >= 1600 — wide desktop.
  extraLarge(1600);

  const WindowSizeClass(this.minWidth);

  /// The narrowest width that still belongs to this class.
  final double minWidth;

  /// The class [width] falls into.
  static WindowSizeClass fromWidth(double width) {
    if (width >= WindowSizeClass.extraLarge.minWidth) {
      return WindowSizeClass.extraLarge;
    }
    if (width >= WindowSizeClass.large.minWidth) {
      return WindowSizeClass.large;
    }
    if (width >= WindowSizeClass.expanded.minWidth) {
      return WindowSizeClass.expanded;
    }
    if (width >= WindowSizeClass.medium.minWidth) {
      return WindowSizeClass.medium;
    }
    return WindowSizeClass.compact;
  }

  bool get isCompact => this == WindowSizeClass.compact;

  /// True for anything a one-column phone layout is meant for. Kept
  /// separate from [isCompact] so a call site reads as a statement about
  /// the layout rather than about the enum.
  bool get isPhone => this == WindowSizeClass.compact;

  /// True from [other] upwards, so `atLeast(expanded)` reads the way the
  /// comparison is spoken.
  bool atLeast(WindowSizeClass other) => index >= other.index;

  bool isBelow(WindowSizeClass other) => index < other.index;

  /// Picks the value for this class, falling back down the scale when a
  /// band is left unspecified: [large] with only [compact] and [expanded]
  /// given resolves to the [expanded] value.
  T resolve<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
    T? extraLarge,
  }) {
    switch (this) {
      case WindowSizeClass.extraLarge:
        return extraLarge ?? large ?? expanded ?? medium ?? compact;
      case WindowSizeClass.large:
        return large ?? expanded ?? medium ?? compact;
      case WindowSizeClass.expanded:
        return expanded ?? medium ?? compact;
      case WindowSizeClass.medium:
        return medium ?? compact;
      case WindowSizeClass.compact:
        return compact;
    }
  }

  /// The gutter a page's content sits in at this width. One number in one
  /// place, rather than the `< 780 ? 16 : 24` that used to be copied into
  /// every page body.
  double get pagePadding => resolve(compact: 16, medium: 20, expanded: 24);
}

/// The window's size class, measured against the whole window.
///
/// Use this for chrome that answers to the device — the shell's
/// navigation, a dialog sizing itself against the screen. For anything
/// laid out *inside* a page, prefer [ResponsiveBuilder]: a page beside a
/// 284px sidebar is a good deal narrower than the window it sits in.
extension WindowSizeContext on BuildContext {
  WindowSizeClass get windowSize =>
      WindowSizeClass.fromWidth(MediaQuery.sizeOf(this).width);
}

/// A [LayoutBuilder] that hands down the size class of its own
/// constraints, so a widget adapts to the room it actually has.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    WindowSizeClass size,
    BoxConstraints constraints,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // An unbounded width (inside a horizontal scroll view, say) has no
        // size class of its own; fall back to the window's.
        final width =
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        return builder(context, WindowSizeClass.fromWidth(width), constraints);
      },
    );
  }
}
