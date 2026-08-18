import 'package:flutter/material.dart';

/// Width at or above which the sidebar renders in full (284px).
const double kShellExpandedBreakpoint = 1024;

/// Width at or above which the sidebar renders as a 72px icon rail.
/// Below it the sidebar moves into a drawer.
const double kShellRailBreakpoint = 760;

/// Exposes the shell's drawer to pages nested inside it, so a page header
/// can render a menu button without reaching for the shell's [Scaffold].
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.hasDrawer,
    required this.openDrawer,
    required super.child,
  });

  /// True when the shell is narrow enough to keep its nav in a drawer.
  final bool hasDrawer;

  final VoidCallback openDrawer;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      hasDrawer != oldWidget.hasDrawer || openDrawer != oldWidget.openDrawer;
}
