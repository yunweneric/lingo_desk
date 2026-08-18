import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_mark.dart';
import '../../../app_settings/presentation/widgets/create_app_dialog.dart';
import '../../domain/entities/app_overview.dart';
import '../bloc/app_management_bloc.dart';
import '../bloc/app_management_event.dart';
import '../bloc/app_management_state.dart';

part '../widgets/dashboard_cards.dart';
part '../widgets/dashboard_content.dart';
part '../widgets/dashboard_controls.dart';
part '../widgets/dashboard_header.dart';
part '../widgets/dashboard_shared.dart';
part '../widgets/dashboard_sidebar.dart';
part '../widgets/projects_table.dart';

/// App Management Dashboard: the entry point listing every
/// localization project with live stats.
class AppDashboardPage extends StatelessWidget {
  const AppDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AppManagementBloc>()..add(LoadAppsEvent()),
      child: const _DashboardShell(),
    );
  }
}

class _DashboardShell extends StatefulWidget {
  const _DashboardShell();

  @override
  State<_DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<_DashboardShell> with RouteAware {
  final AppSettingsController _settings = getIt<AppSettingsController>();
  final ScrollController _scrollController = ScrollController();
  AppManagementBloc? _bloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<AppManagementBloc>();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  /// Reloads the stats whenever navigation returns to the dashboard,
  /// so numbers reflect edits made in settings/upload/editor.
  @override
  void didPopNext() {
    _bloc?.add(LoadAppsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1024;

              return Row(
                children: [
                  if (isWide) _AppSidebar(scrollController: _scrollController),
                  Expanded(
                    child: _DashboardContent(
                      scrollController: _scrollController,
                      themeMode: _settings.themeMode,
                      onThemeModeChanged: _settings.setThemeMode,
                      selectedLanguage: _settings.uiLanguage,
                      onLanguageChanged: _settings.setUiLanguage,
                      showMobileBrand: !isWide,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Section anchors for the sidebar's scroll jumps.
final GlobalKey _appsSectionKey = GlobalKey(debugLabel: 'apps-section');
final GlobalKey _languageHealthKey = GlobalKey(debugLabel: 'language-health');

Future<void> _openCreateApp(BuildContext context) async {
  final app = await CreateAppDialog.show(context);
  if (app == null || !context.mounted) {
    return;
  }

  // Offer to import files right away; the dashboard stats refresh via
  // the shell's RouteAware.didPopNext when the dialogs close.
  final uploadNow = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text('"${app.name}" created'),
          content: const Text(
            'Do you want to upload your existing JSON translation files now? '
            'You can also do this later from the dashboard.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Upload files'),
            ),
          ],
        ),
  );

  if (uploadNow == true && context.mounted) {
    context.push(AppRoutes.fileUpload(app.id), extra: app);
  }
}

/// Resolves which app a sidebar action should target: directly with a
/// single app, via a chooser with several, or the create modal when none.
Future<AppOverview?> _pickApp(BuildContext context) async {
  final state = context.read<AppManagementBloc>().state;
  final overviews =
      state is AppManagementLoaded ? state.overviews : const <AppOverview>[];

  if (overviews.isEmpty) {
    await _openCreateApp(context);
    return null;
  }
  if (overviews.length == 1) {
    return overviews.first;
  }

  return showDialog<AppOverview>(
    context: context,
    builder:
        (dialogContext) => SimpleDialog(
          title: const Text('Choose an app'),
          children: [
            for (final overview in overviews)
              SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(overview),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overview.app.name,
                        style: Theme.of(dialogContext).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${overview.app.sourceLanguage}.json - '
                        '${overview.keyCount} keys',
                        style: LingoDeskTheme.codeStyle.copyWith(
                          fontSize: 12,
                          color: LingoDeskTokens.of(dialogContext).muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
  );
}

/// Smoothly scrolls the dashboard to a section anchor, building lazy
/// slivers first when needed.
Future<void> _scrollToSection(
  ScrollController controller,
  GlobalKey key,
) async {
  const duration = Duration(milliseconds: 240);
  const curve = Curves.easeOutCubic;

  final sectionContext = key.currentContext;
  if (sectionContext != null) {
    await Scrollable.ensureVisible(
      sectionContext,
      duration: duration,
      curve: curve,
    );
    return;
  }
  if (!controller.hasClients) {
    return;
  }
  // The sliver isn't built yet: scroll to the end, then anchor to it.
  await controller.animateTo(
    controller.position.maxScrollExtent,
    duration: duration,
    curve: curve,
  );
  await WidgetsBinding.instance.endOfFrame;
  final retryContext = key.currentContext;
  if (retryContext != null && retryContext.mounted) {
    await Scrollable.ensureVisible(
      retryContext,
      duration: duration,
      curve: curve,
    );
  }
}

void _openAppSettings(BuildContext context, AppOverview overview) {
  context.push(AppRoutes.appSettings(overview.app.id), extra: overview.app);
}

void _openFileUpload(BuildContext context, AppOverview overview) {
  context.push(AppRoutes.fileUpload(overview.app.id), extra: overview.app);
}

void _openEditor(BuildContext context, AppOverview overview) {
  context.push(AppRoutes.editor(overview.app.id));
}

Future<void> _confirmDeleteApp(
  BuildContext context,
  AppOverview overview,
) async {
  final bloc = context.read<AppManagementBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text('Delete "${overview.app.name}"?'),
          content: const Text(
            'This permanently removes the app and all of its translations. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: LingoDeskColors.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
  );
  if (confirmed ?? false) {
    bloc.add(DeleteAppEvent(overview.app.id));
  }
}

List<_Metric> _dashboardMetrics(AppManagementLoaded state) {
  final missing = state.totalMissing;

  return [
    _Metric(
      label: 'Apps',
      value: state.overviews.length.toString(),
      detail: 'Local workspace',
      icon: HugeIcons.strokeRoundedFolder02,
    ),
    _Metric(
      label: 'Total keys',
      value: state.totalKeys.toString(),
      detail: 'Across all apps',
      icon: HugeIcons.strokeRoundedKey01,
    ),
    _Metric(
      label: 'Coverage',
      value: '${(state.coverage * 100).round()}%',
      detail: '${state.activeLanguages.length} target locales',
      icon: HugeIcons.strokeRoundedChartBarIncreasing,
    ),
    _Metric(
      label: 'Missing',
      value: missing.toString(),
      detail: missing == 0 ? 'All clear' : 'Needs review',
      icon: HugeIcons.strokeRoundedAlertCircle,
      isPositive: missing == 0,
    ),
  ];
}

/// Derived status of an app for the dashboard table.
({String label, Color color}) _statusOf(AppOverview overview) {
  if (overview.keyCount == 0) {
    return (label: 'New', color: LingoDeskColors.brandTeal);
  }
  if (overview.isComplete) {
    return (label: 'Complete', color: LingoDeskColors.complete);
  }
  return (label: 'Missing', color: LingoDeskColors.warning);
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.isPositive = true,
  });

  final String label;
  final String value;
  final String detail;
  final List<List<dynamic>> icon;
  final bool isPositive;
}

class _SidebarItemData {
  const _SidebarItemData({
    required this.label,
    required this.icon,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool isActive;
  final VoidCallback? onTap;
}
