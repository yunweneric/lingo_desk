import 'package:flutter/material.dart';

import 'landing/landing_app.dart';

/// Entry point for the marketing site.
///
/// Built with `flutter build web -t lib/main_landing.dart`. It shares the
/// theme, brandmark and responsive helpers with the product but none of
/// its bootstrap: no dependency injection, no local storage, no router —
/// so none of that reaches the web bundle.
void main() {
  runApp(const LandingApp());
}
