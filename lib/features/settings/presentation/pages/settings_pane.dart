import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/responsive/touch.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/app_shell_scope.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_page_header.dart';

/// Shared chassis for the settings panes.
///
/// Each pane is its own sidebar item and its own route, so the thing that
/// used to be a tab bar is now the rail. What is left to share is the
/// chrome: the breadcrumb band, the gutters, and the scroll.
class SettingsPane extends StatelessWidget {
  const SettingsPane({
    super.key,
    required this.title,
    required this.listenable,
    required this.builder,
  });

  /// Last breadcrumb segment, and the name of the sidebar item that leads
  /// here.
  final String title;

  /// The controller(s) this pane reads; the body rebuilds when they
  /// notify, since settings write straight through rather than round-trip
  /// through a bloc.
  final Listenable listenable;

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    // On a phone the nav is a bottom bar carrying one Settings entry, so
    // the rail is not there to move between panes and the pane has to
    // offer that itself. This asks the window's size class, not the
    // pane's: a tablet leaves the page a compact-width column but still
    // shows the rail beside it, and two navigations would be one too many.
    final needsSwitcher =
        AppShellScope.maybeOf(context)?.sizeClass.isCompact ?? false;

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: Column(
          children: [
            WorkspacePageHeader(
              breadcrumb: [
                Crumb.workspace,
                const Crumb('Settings'),
                Crumb(title),
              ],
            ),
            if (needsSwitcher) const SettingsPaneSwitcher(),
            Expanded(
              child: ListenableBuilder(
                listenable: listenable,
                builder: (context, _) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontal = constraints.maxWidth < 780
                          ? 16.0
                          : 24.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          20,
                          horizontal,
                          28,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: builder(context),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Moves between the settings panes when the sidebar isn't there to.
///
/// Reads the same [kAppDestinations] the rail does, filtered to the
/// settings group, so a pane added to the nav shows up here without a
/// second list to remember.
class SettingsPaneSwitcher extends StatelessWidget {
  const SettingsPaneSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final panes = kAppDestinations
        .where((destination) => destination.group == NavGroup.settings)
        .toList();
    final location = GoRouterState.of(context).uri.path;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            for (final pane in panes)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PanePill(
                  destination: pane,
                  selected: pane.isActive(location),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PanePill extends StatelessWidget {
  const _PanePill({required this.destination, required this.selected});

  final AppDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final foreground = selected ? tokens.foreground : tokens.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : () => destination.onTap(context),
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          height: kTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? tokens.active : Colors.transparent,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
            border: Border.all(
              color: selected ? tokens.border : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LingoDeskIcon(destination.icon, size: 17, color: foreground),
              const SizedBox(width: 8),
              Text(
                destination.label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
