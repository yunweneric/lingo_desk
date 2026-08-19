import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../../../../core/widgets/workspace_toolbar.dart';
import '../app_actions.dart';
import '../bloc/app_management_bloc.dart';
import '../bloc/app_management_event.dart';
import '../bloc/app_management_state.dart';
import '../widgets/apps_search_field.dart';
import '../widgets/apps_summary_card.dart';
import '../widgets/apps_table.dart';
import '../../../../core/localization/export.dart';

/// Every localization app in one table, above workspace-wide counters and
/// the overall translation-file progress.
class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> with RouteAware {
  final AppSettingsController _settings = getIt<AppSettingsController>();
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
    super.dispose();
  }

  /// Counters go stale while the editor, upload or settings pages are on
  /// top, so reload whenever we come back.
  @override
  void didPopNext() {
    _bloc?.add(LoadAppsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: BlocBuilder<AppManagementBloc, AppManagementState>(
          builder: (context, state) {
            return Column(
              children: [
                ListenableBuilder(
                  listenable: _settings,
                  builder: (context, _) {
                    return WorkspacePageHeader(
                      breadcrumb: [
                        Crumb.workspace,
                        Crumb(LocaleKeys.navApps.tr()),
                      ],
                      actions: [
                        const AppsSearchField(),
                        ThemeModeSwitcher(
                          themeMode: _settings.themeMode,
                          onChanged: _settings.setThemeMode,
                        ),
                        OutlinedButton.icon(
                          onPressed: () => openImportProject(context),
                          icon: const LingoDeskIcon(
                            HugeIcons.strokeRoundedFolderAdd,
                            size: 18,
                          ),
                          label: Text(LocaleKeys.appsImportProject.tr()),
                        ),
                        FilledButton.icon(
                          onPressed: () => openCreateApp(context),
                          icon: const LingoDeskIcon(
                            HugeIcons.strokeRoundedAdd01,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(LocaleKeys.appsNewApp.tr()),
                        ),
                      ],
                      // Four controls, one of them 280px wide, would take
                      // three rows of a phone's header before the table
                      // got a pixel. Search is what this page is for, so
                      // it keeps the full width; creating an app sits
                      // beside it and importing moves to the bottom nav's
                      // own Import destination.
                      compactActions: [
                        const AppsSearchField(expand: true),
                        Row(
                          children: [
                            ThemeModeSwitcher(
                              themeMode: _settings.themeMode,
                              onChanged: _settings.setThemeMode,
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: () => openCreateApp(context),
                              icon: const LingoDeskIcon(
                                HugeIcons.strokeRoundedAdd01,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(LocaleKeys.appsNewApp.tr()),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppManagementState state) {
    // Cross-fade the three states so a reload after returning from the
    // editor refreshes in place instead of flashing a spinner.
    return AnimatedSwitcher(
      duration: LingoDeskMotion.standard,
      switchInCurve: LingoDeskMotion.curve,
      switchOutCurve: LingoDeskMotion.curve,
      // The switcher stacks its children; without this the shrink-wrapped
      // scroll view floats in the middle of the page instead of starting
      // under the header.
      layoutBuilder: topAlignedSwitcherLayout,
      child: KeyedSubtree(
        key: ValueKey<String>(state.runtimeType.toString()),
        child: _bodyFor(context, state),
      ),
    );
  }

  Widget _bodyFor(BuildContext context, AppManagementState state) {
    if (state is AppManagementError) {
      return WorkspaceErrorState(
        message: state.message,
        onRetry: () => context.read<AppManagementBloc>().add(LoadAppsEvent()),
      );
    }
    if (state is! AppManagementLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ResponsiveBuilder(
      builder: (context, size, constraints) {
        final horizontal = size.pagePadding;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(child: AppsSummaryCard(state: state)),
              const SizedBox(height: 16),
              if (state.overviews.isEmpty)
                WorkspaceEmptyState(
                  icon: HugeIcons.strokeRoundedFolder02,
                  title: LocaleKeys.appsEmptyTitle.tr(),
                  message: LocaleKeys.appsEmptyMessage.tr(),
                  actionLabel: LocaleKeys.appsImportProject.tr(),
                  actionIcon: HugeIcons.strokeRoundedFolderAdd,
                  onAction: () => openImportProject(context),
                )
              else
                FadeSlideIn.staggered(index: 1, child: AppsTable(state: state)),
            ],
          ),
        );
      },
    );
  }
}
