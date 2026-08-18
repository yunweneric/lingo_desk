import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_management/domain/entities/app.dart';
import '../../features/app_management/presentation/pages/app_dashboard_page.dart';
import '../../features/app_settings/presentation/pages/app_settings_page.dart';
import '../../features/file_upload/presentation/pages/file_upload_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/translation_editor/presentation/pages/translation_editor_page.dart';
import '../preferences/app_settings_controller.dart';

/// Observes the root navigator so pages can react to being returned to
/// (e.g. the dashboard reloads its stats via [RouteAware.didPopNext]).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Route paths used across the app.
class AppRoutes {
  const AppRoutes._();

  static const onboarding = '/onboarding';
  static const dashboard = '/';

  static String appSettings(String appId) => '/apps/$appId/settings';
  static String fileUpload(String appId, {bool popOnImport = false}) =>
      '/apps/$appId/upload${popOnImport ? '?pop=1' : ''}';
  static String editor(String appId) => '/apps/$appId/editor';
}

/// Builds the app's [GoRouter].
///
/// Every navigation is a fade (240ms, ease-out-cubic — the design
/// system's motion tokens). Onboarding is enforced with a redirect that
/// re-evaluates when [settings] notifies.
GoRouter buildAppRouter(AppSettingsController settings) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    observers: [appRouteObserver],
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
        pageBuilder:
            (context, state) => _fadePage(
              state,
              OnboardingPage(onComplete: settings.completeOnboarding),
            ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder:
            (context, state) => _fadePage(state, const AppDashboardPage()),
      ),
      GoRoute(
        path: '/apps/:id/settings',
        // Editing needs the App object; a bare deep link falls back to
        // the dashboard.
        redirect:
            (context, state) => state.extra is App ? null : AppRoutes.dashboard,
        pageBuilder:
            (context, state) =>
                _fadePage(state, AppSettingsPage(app: state.extra as App)),
      ),
      GoRoute(
        path: '/apps/:id/upload',
        redirect:
            (context, state) => state.extra is App ? null : AppRoutes.dashboard,
        pageBuilder:
            (context, state) => _fadePage(
              state,
              FileUploadPage(
                app: state.extra as App,
                popOnImport: state.uri.queryParameters['pop'] == '1',
              ),
            ),
      ),
      GoRoute(
        path: '/apps/:id/editor',
        pageBuilder:
            (context, state) => _fadePage(
              state,
              TranslationEditorPage(appId: state.pathParameters['id']!),
            ),
      ),
    ],
  );
}

CustomTransitionPage<Object?> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<Object?>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOutCubic).animate(animation),
        child: child,
      );
    },
  );
}
