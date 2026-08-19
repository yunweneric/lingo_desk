import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_translation/presentation/pages/ai_providers_page.dart';
import '../../features/app_management/domain/entities/app.dart';
import '../../features/app_management/presentation/pages/app_dashboard_page.dart';
import '../../features/app_management/presentation/pages/apps_page.dart';
import '../../features/app_settings/presentation/pages/app_settings_page.dart';
import '../../features/file_upload/presentation/pages/file_upload_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/settings/presentation/pages/settings_appearance_page.dart';
import '../../features/settings/presentation/pages/settings_languages_page.dart';
import '../../features/settings/presentation/pages/settings_profile_page.dart';
import '../../features/settings/presentation/pages/settings_updates_page.dart';
import '../../features/translation_editor/presentation/pages/translation_editor_page.dart';
import '../preferences/app_settings_controller.dart';
import '../theme/lingo_desk_motion.dart';
import '../widgets/app_shell.dart';

/// Observes the shell navigator so pages can react to being returned to
/// (e.g. the dashboard reloads its stats via [RouteAware.didPopNext]).
///
/// It must be attached to the [ShellRoute], not the root navigator:
/// everything below the sidebar is pushed onto the shell's navigator.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Route paths used across the app.
class AppRoutes {
  const AppRoutes._();

  static const onboarding = '/onboarding';
  static const dashboard = '/';
  static const apps = '/apps';

  /// Project import: scan a folder, then create the app from it.
  static const importProject = '/import';

  /// Settings is a group, not a page: each pane is its own sidebar item
  /// and its own route. The bare path redirects to the first pane so old
  /// links and the sidebar footer still land somewhere.
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsAppearance = '/settings/appearance';
  static const settingsLanguages = '/settings/languages';
  static const settingsUpdates = '/settings/updates';

  /// API keys for the AI translation providers.
  static const aiProviders = '/ai-providers';

  /// Dashboard deep link that scrolls to a section anchor once loaded.
  static String dashboardSection(String section) => '/?section=$section';

  static String appSettings(String appId) => '/apps/$appId/settings';
  static String fileUpload(String appId, {bool popOnImport = false}) =>
      '/apps/$appId/upload${popOnImport ? '?pop=1' : ''}';
  static String editor(String appId) => '/apps/$appId/editor';
}

/// Builds the app's [GoRouter].
///
/// Every page except onboarding renders inside [AppShell], so the sidebar
/// is mounted once and persists across navigation. Every navigation is a
/// fade-and-rise on the shared motion tokens ([LingoDeskMotion.page]).
/// Onboarding is enforced with a redirect that re-evaluates when
/// [settings] notifies.
GoRouter buildAppRouter(AppSettingsController settings) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: settings,
    redirect: (context, state) {
      final onOnboarding = state.uri.path == AppRoutes.onboarding;
      if (!settings.onboardingComplete && !onOnboarding) {
        return AppRoutes.onboarding;
      }
      if (settings.onboardingComplete && onOnboarding) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _fadePage(
          state,
          OnboardingPage(onComplete: settings.completeOnboarding),
        ),
      ),
      ShellRoute(
        observers: [appRouteObserver],
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => _fadePage(
              state,
              AppDashboardPage(section: state.uri.queryParameters['section']),
            ),
          ),
          GoRoute(
            path: AppRoutes.apps,
            pageBuilder: (context, state) => _fadePage(state, const AppsPage()),
          ),
          GoRoute(
            path: AppRoutes.importProject,
            pageBuilder: (context, state) =>
                _fadePage(state, const FileUploadPage()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            redirect: (context, state) => AppRoutes.settingsProfile,
          ),
          GoRoute(
            path: AppRoutes.settingsProfile,
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsProfilePage()),
          ),
          GoRoute(
            path: AppRoutes.settingsAppearance,
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsAppearancePage()),
          ),
          GoRoute(
            path: AppRoutes.settingsLanguages,
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsLanguagesPage()),
          ),
          GoRoute(
            path: AppRoutes.settingsUpdates,
            pageBuilder: (context, state) =>
                _fadePage(state, const SettingsUpdatesPage()),
          ),
          GoRoute(
            path: AppRoutes.aiProviders,
            pageBuilder: (context, state) =>
                _fadePage(state, const AiProvidersPage()),
          ),
          GoRoute(
            path: '/apps/:id/settings',
            // Editing needs the App object; a bare deep link falls back to
            // the dashboard.
            redirect: (context, state) =>
                state.extra is App ? null : AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                _fadePage(state, AppSettingsPage(app: state.extra as App)),
          ),
          GoRoute(
            path: '/apps/:id/upload',
            redirect: (context, state) =>
                state.extra is App ? null : AppRoutes.dashboard,
            pageBuilder: (context, state) => _fadePage(
              state,
              FileUploadPage(
                app: state.extra as App,
                popOnImport: state.uri.queryParameters['pop'] == '1',
              ),
            ),
          ),
          GoRoute(
            path: '/apps/:id/editor',
            pageBuilder: (context, state) => _fadePage(
              state,
              TranslationEditorPage(appId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Fade plus a short rise, so a page arrives rather than blinks on.
///
/// The outgoing page only fades — sliding both directions at once reads
/// as the window scrolling, not as one page replacing another.
CustomTransitionPage<Object?> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<Object?>(
    key: state.pageKey,
    child: child,
    transitionDuration: LingoDeskMotion.page,
    reverseTransitionDuration: LingoDeskMotion.page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final eased = CurvedAnimation(
        parent: animation,
        curve: LingoDeskMotion.entrance,
        reverseCurve: LingoDeskMotion.curve,
      );

      if (!LingoDeskMotion.enabled(context)) {
        return FadeTransition(opacity: eased, child: child);
      }

      return FadeTransition(
        opacity: eased,
        child: SlideTransition(
          position: Tween<Offset>(
            // Fraction of the page height: ~8px on a 700px pane.
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(eased),
          child: child,
        ),
      );
    },
  );
}
