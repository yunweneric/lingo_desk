import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'di/injection_container.dart';
import 'preferences/app_settings_controller.dart';
import 'router/app_router.dart';
import 'theme/lingo_desk_theme.dart';
import 'widgets/lingo_desk_toast.dart';

/// Root application widget
///
/// Configures the MaterialApp with theme, go_router routing (fade
/// transitions), and global settings. Theme mode, UI language, and
/// onboarding completion are persisted via [AppSettingsController].
class LingoDeskApp extends StatefulWidget {
  const LingoDeskApp({super.key});

  @override
  State<LingoDeskApp> createState() => _LingoDeskAppState();
}

class _LingoDeskAppState extends State<LingoDeskApp> {
  late final AppSettingsController _settings;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _settings = getIt<AppSettingsController>();
    _router = buildAppRouter(_settings);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'LingoDesk',
          debugShowCheckedModeBanner: false,
          theme: LingoDeskTheme.light(),
          darkTheme: LingoDeskTheme.dark(),
          themeMode: _settings.themeMode,
          locale: Locale(_settings.uiLanguage),
          routerConfig: _router,
          // Above the router, so a toast survives the navigation that
          // often triggers it and paints over dialogs.
          builder:
              (context, child) =>
                  LingoDeskToastHost(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
