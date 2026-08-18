import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';

/// Exposes the shell's chrome to pages nested inside it, so a page header
/// can render a menu button, or lay itself out against the width the shell
/// actually left it, without reaching for the shell's [Scaffold].
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.hasDrawer,
    required this.openDrawer,
    required this.sizeClass,
    required this.contentSizeClass,
    required super.child,
  });

  /// True when the shell keeps its nav behind a drawer. False both on a
  /// phone, where the nav is a bottom bar, and on a desktop window, where
  /// the sidebar is always on screen.
  final bool hasDrawer;

  final VoidCallback openDrawer;

  /// The size class of the whole shell — what decides the nav pattern.
  final WindowSizeClass sizeClass;

  /// The size class of the pane left for the page, once the sidebar has
  /// taken its width. This is the one a page's own layout answers to.
  final WindowSizeClass contentSizeClass;

  static AppShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>();
  }

  /// The page pane's size class, or the window's for anything rendered
  /// outside the shell (onboarding, dialogs).
  static WindowSizeClass sizeOf(BuildContext context) =>
      maybeOf(context)?.contentSizeClass ?? context.windowSize;

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      hasDrawer != oldWidget.hasDrawer ||
      openDrawer != oldWidget.openDrawer ||
      sizeClass != oldWidget.sizeClass ||
      contentSizeClass != oldWidget.contentSizeClass;
}
