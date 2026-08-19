import 'package:flutter/material.dart';

import 'landing/landing_app.dart';

/// Entry point for the marketing site.
///
/// Built with `flutter build web -t lib/main_landing.dart`. It shares the
/// theme, brandmark and responsive helpers with the product but none of
/// its bootstrap: no dependency injection, no local storage, no router —
/// so none of that reaches the web bundle.
void main() {
  // Read before [runApp]: once a Navigator is mounted, Flutter's browser
  // history integration normalises the hash and the anchor is gone.
  final anchor = Uri.base.fragment;

  runApp(LandingApp(initialAnchor: anchor));
}
