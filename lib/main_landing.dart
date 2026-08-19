import 'package:flutter/material.dart';

import 'core/localization/export.dart';
import 'landing/landing_app.dart';

/// Entry point for the marketing site.
///
/// Built with `flutter build web -t lib/main_landing.dart`. It shares the
/// theme, brandmark, translations and responsive helpers with the product
/// but none of its bootstrap: no dependency injection, no router — so none
/// of that reaches the web bundle.
void main() async {
  // Read before [runApp]: once a Navigator is mounted, Flutter's browser
  // history integration normalises the hash and the anchor is gone.
  final anchor = Uri.base.fragment;

  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalization.ensureInitialized();

  // No `startLocale`: a first visit is served in the browser's language
  // when we have it, and the picker in the nav saves the visitor's choice
  // for the next one.
  runApp(AppLocalization.wrap(child: LandingApp(initialAnchor: anchor)));
}
