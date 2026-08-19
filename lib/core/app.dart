import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'di/injection_container.dart';
import 'localization/export.dart';
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
        final palette = _settings.themeVariant.palette;
        return MaterialApp.router(
          title: 'LingoDesk',
          debugShowCheckedModeBanner: false,
          theme: LingoDeskTheme.light(palette),
          darkTheme: LingoDeskTheme.dark(palette),
          themeMode: _settings.themeMode,
          locale: AppLocalization.localeOf(context),
          supportedLocales: AppLocalization.supportedLocalesOf(context),
          localizationsDelegates: AppLocalization.delegatesOf(context),
          routerConfig: _router,
          // Above the router, so a toast survives the navigation that
          // often triggers it and paints over dialogs.
          //
          // Text scaling is capped on the way in: the grids and tables are
          // laid out in real pixels, and a 2x accessibility scale turns a
          // row of columns into a row of overflows. 1.4 is generous enough
          // to be worth having and small enough to still fit.
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.4,
            child: LingoDeskToastHost(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
