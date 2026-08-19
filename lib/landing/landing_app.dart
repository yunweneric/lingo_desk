import 'package:flutter/material.dart';

import '../core/theme/lingo_desk_theme.dart';
import 'landing_page.dart';
import 'state/landing_controller.dart';

/// The landing site's root.
///
/// It builds the app's own light and dark themes from whichever palette
/// the visitor has selected, which is what lets the "built with Flutter"
/// section repaint the entire page from a single tap.
class LandingApp extends StatefulWidget {
  const LandingApp({super.key, this.initialAnchor = ''});

  /// Section named in the URL fragment at load, e.g. `download`.
  final String initialAnchor;

  @override
  State<LandingApp> createState() => _LandingAppState();
}

class _LandingAppState extends State<LandingApp> {
  final LandingController _controller = LandingController();

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final palette = _controller.variant.palette;
        return MaterialApp(
          title: 'LingoDesk — Localization manager for developers',
          debugShowCheckedModeBanner: false,
          theme: LingoDeskTheme.light(palette),
          darkTheme: LingoDeskTheme.dark(palette),
          themeMode: _controller.isDark ? ThemeMode.dark : ThemeMode.light,
          home: LandingPage(
            controller: _controller,
            initialAnchor: widget.initialAnchor,
          ),
        );
      },
    );
  }
}
