import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../features/app_management/presentation/app_actions.dart';
import '../../features/app_management/presentation/bloc/app_management_bloc.dart';
import '../../features/app_management/presentation/bloc/app_management_event.dart';
import '../di/injection_container.dart';
import '../preferences/app_settings_controller.dart';
import '../router/app_router.dart';
import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_animations.dart';
import 'app_shell_scope.dart';
import 'lingo_desk_icon.dart';
import 'lingo_desk_mark.dart';

/// Persistent frame around every signed-in page: the sidebar on the left,
/// the routed page on the right.
///
/// Owns the single [AppManagementBloc] instance for the whole shell, so
/// the dashboard, the apps page and the sidebar's app chooser all read the
/// same overviews and one load serves them all.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  /// Current route path, used to highlight the active sidebar item.
  final String location;

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return BlocProvider(
      create: (_) => getIt<AppManagementBloc>()..add(LoadAppsEvent()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final hasDrawer = width < kShellRailBreakpoint;
          final collapsed = width < kShellExpandedBreakpoint;

          return AppShellScope(
            hasDrawer: hasDrawer,
            openDrawer: _openDrawer,
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: tokens.background,
              drawer:
                  hasDrawer
                      ? Drawer(
                        width: 284,
                        backgroundColor: tokens.sidebar,
                        shape: const RoundedRectangleBorder(),
                        child: AppSidebar(
                          location: widget.location,
                          onItemTap: () => Navigator.of(context).pop(),
                        ),
                      )
                      : null,
              body: Row(
                children: [
                  if (!hasDrawer)
                    AppSidebar(location: widget.location, collapsed: collapsed),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Primary navigation. Renders full width (284px) by default, or as a
/// 72px icon rail when [collapsed].
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.location,
    this.collapsed = false,
    this.onItemTap,
  });

  final String location;
  final bool collapsed;

  /// Called after any item is activated; the drawer uses it to close.
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    final width = collapsed ? 72.0 : 284.0;

    return AnimatedContainer(
      duration: LingoDeskMotion.standard,
      curve: LingoDeskMotion.curve,
      width: width,
      decoration: BoxDecoration(
        color: tokens.sidebar,
        border: Border(right: BorderSide(color: tokens.border)),
      ),
      // The content is laid out at its final width immediately and
      // revealed as the rail grows, so labels slide out from behind the
      // edge instead of reflowing on every frame of the animation.
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: width,
          maxWidth: width,
          child: SafeArea(
            child: AnimatedPadding(
              duration: LingoDeskMotion.standard,
              curve: LingoDeskMotion.curve,
              padding: EdgeInsets.all(collapsed ? 10 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        collapsed
                            ? const EdgeInsets.only(bottom: 18)
                            : const EdgeInsets.fromLTRB(8, 8, 8, 20),
                    child: LingoDeskMark(
                      size: collapsed ? 28 : 34,
                      reversed: tokens.isDark,
                      showWordmark: !collapsed,
                    ),
                  ),
                  _SidebarSection(
                    collapsed: collapsed,
                    items: [
                      _SidebarItemData(
                        label: 'Dashboard',
                        icon: HugeIcons.strokeRoundedDashboardSquare01,
                        isActive: location == AppRoutes.dashboard,
                        onTap: () => context.go(AppRoutes.dashboard),
                      ),
                      _SidebarItemData(
                        label: 'Apps',
                        icon: HugeIcons.strokeRoundedFolder02,
                        // The editor and per-app pages hang off Apps;
                        // uploading into an app belongs to Import.
                        isActive:
                            location.startsWith(AppRoutes.apps) &&
                            !location.endsWith('/upload'),
                        onTap: () => context.go(AppRoutes.apps),
                      ),
                      _SidebarItemData(
                        label: 'Import',
                        icon: HugeIcons.strokeRoundedFileUpload,
                        isActive:
                            location == AppRoutes.importProject ||
                            location.endsWith('/upload'),
                        onTap: () => openImportProject(context),
                      ),
                      _SidebarItemData(
                        label: 'Settings',
                        icon: HugeIcons.strokeRoundedSettings01,
                        isActive: location == AppRoutes.settings,
                        onTap: () => context.go(AppRoutes.settings),
                      ),
                    ],
                    onItemTap: onItemTap,
                  ),
                  const Spacer(),
                  _SidebarFooter(
                    collapsed: collapsed,
                    onTap: () {
                      context.go(AppRoutes.settings);
                      onItemTap?.call();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.items,
    required this.collapsed,
    this.onItemTap,
  });

  final List<_SidebarItemData> items;
  final bool collapsed;
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          _SidebarItem(item: item, collapsed: collapsed, onItemTap: onItemTap),
      ],
    );
  }
}

/// A nav row that answers the pointer before it is clicked: the fill
/// warms on hover, the label and icon come up to full contrast, and the
/// active item grows a teal bar against the rail's inner edge.
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.item,
    required this.collapsed,
    this.onItemTap,
  });

  final _SidebarItemData item;
  final bool collapsed;
  final VoidCallback? onItemTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final item = widget.item;
    final collapsed = widget.collapsed;
    final foreground =
        item.isActive || _hovered ? tokens.foreground : tokens.muted;
    final background =
        item.isActive
            ? tokens.active
            : _hovered
            ? tokens.active.withValues(alpha: 0.6)
            : Colors.transparent;

    final row = AnimatedContainer(
      duration: LingoDeskMotion.fast,
      curve: LingoDeskMotion.curve,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedTint(
        color: foreground,
        builder: (context, tint) {
          final icon = LingoDeskIcon(item.icon, size: 18, color: tint);

          if (collapsed) {
            return Center(child: icon);
          }

          return Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: LingoDeskMotion.fast,
                  curve: LingoDeskMotion.curve,
                  style:
                      Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: tint) ??
                      TextStyle(color: tint),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final indicator = Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedContainer(
          duration: LingoDeskMotion.standard,
          curve: LingoDeskMotion.curve,
          width: 3,
          height: item.isActive ? 18 : 0,
          decoration: BoxDecoration(
            color: LingoDeskColors.brandTeal,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );

    final content = Stack(children: [row, indicator]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap:
              item.onTap == null
                  ? null
                  : () {
                    item.onTap!.call();
                    widget.onItemTap?.call();
                  },
          borderRadius: BorderRadius.circular(12),
          // The rail's own tint already reads as hover; Material's would
          // stack a second wash on top of it.
          hoverColor: Colors.transparent,
          child:
              collapsed
                  ? Tooltip(message: item.label, child: content)
                  : content,
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.collapsed, required this.onTap});

  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final settings = getIt<AppSettingsController>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final avatar = Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: LingoDeskColors.brandTeal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            settings.profileInitials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

        if (collapsed) {
          return Tooltip(
            message: settings.profileName,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: avatar,
            ),
          );
        }

        final subtitle =
            settings.profileEmail.isEmpty
                ? 'Local storage'
                : settings.profileEmail;

        // Deliberately not lifted on hover: this card is a button, and a
        // target that rises out from under the pointer is a target you
        // have to chase.
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.border),
            ),
            child: Row(
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                LingoDeskIcon(
                  HugeIcons.strokeRoundedMoreHorizontal,
                  size: 18,
                  color: tokens.muted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
