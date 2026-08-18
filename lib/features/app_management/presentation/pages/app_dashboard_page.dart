import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../../core/widgets/workspace_toolbar.dart';
import '../app_actions.dart';
import '../bloc/app_management_bloc.dart';
import '../bloc/app_management_event.dart';
import '../bloc/app_management_state.dart';

part '../widgets/dashboard_cards.dart';
part '../widgets/dashboard_content.dart';
part '../widgets/dashboard_header.dart';

/// Workspace overview: headline stats, coverage per app and language
/// health. The apps table itself lives on [AppsPage].
class AppDashboardPage extends StatefulWidget {
  const AppDashboardPage({super.key, this.section});

  /// Optional `?section=` anchor to scroll to once the stats load.
  final String? section;

  @override
  State<AppDashboardPage> createState() => _AppDashboardPageState();
}

class _AppDashboardPageState extends State<AppDashboardPage> with RouteAware {
  final AppSettingsController _settings = getIt<AppSettingsController>();
  final ScrollController _scrollController = ScrollController();
  AppManagementBloc? _bloc;
  String? _pendingSection;

  @override
  void initState() {
    super.initState();
    _pendingSection = widget.section;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<AppManagementBloc>();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
    // The shell's bloc may already be loaded when we arrive from another
    // page, in which case no state change will announce it.
    if (_bloc?.state is AppManagementLoaded) {
      _consumePendingSection();
    }
  }

  @override
  void didUpdateWidget(covariant AppDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section != null && widget.section != oldWidget.section) {
      _pendingSection = widget.section;
      _consumePendingSection();
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

  /// Honours the sidebar's "Languages" deep link once the anchor exists.
  void _consumePendingSection() {
    if (_pendingSection != 'languages') {
      return;
    }
    _pendingSection = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToSection(_scrollController, _languageHealthKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppManagementBloc, AppManagementState>(
      listener: (context, state) {
        if (state is AppManagementLoaded) {
          _consumePendingSection();
        }
      },
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) {
          return _DashboardContent(
            scrollController: _scrollController,
            themeMode: _settings.themeMode,
            onThemeModeChanged: _settings.setThemeMode,
          );
        },
      ),
    );
  }
}

/// Section anchor for the sidebar's "Languages" deep link.
final GlobalKey _languageHealthKey = GlobalKey(debugLabel: 'language-health');

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

List<_Metric> _dashboardMetrics(AppManagementLoaded state) {
  final missing = state.totalMissing;

  return [
    _Metric(
      label: 'Apps',
      value: state.overviews.length,
      detail: 'Local workspace',
      icon: HugeIcons.strokeRoundedFolder02,
    ),
    _Metric(
      label: 'Total keys',
      value: state.totalKeys,
      detail: 'Across all apps',
      icon: HugeIcons.strokeRoundedKey01,
    ),
    _Metric(
      label: 'Coverage',
      value: (state.coverage * 100).round(),
      suffix: '%',
      detail: '${state.activeLanguages.length} target locales',
      icon: HugeIcons.strokeRoundedChartBarIncreasing,
    ),
    _Metric(
      label: 'Missing',
      value: missing,
      detail: missing == 0 ? 'All clear' : 'Needs review',
      icon: HugeIcons.strokeRoundedAlertCircle,
      isPositive: missing == 0,
    ),
  ];
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.suffix = '',
    this.isPositive = true,
  });

  final String label;

  /// Kept numeric so the card can count up to it rather than snapping.
  final num value;

  /// Unit appended to [value], e.g. `%`.
  final String suffix;

  final String detail;
  final List<List<dynamic>> icon;
  final bool isPositive;
}
