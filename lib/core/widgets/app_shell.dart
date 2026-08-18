import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../features/app_management/presentation/app_actions.dart';
import '../../features/app_management/presentation/bloc/app_management_bloc.dart';
import '../../features/app_management/presentation/bloc/app_management_event.dart';
import '../../features/app_management/presentation/bloc/app_management_state.dart';
import '../di/injection_container.dart';
import '../preferences/app_settings_controller.dart';
import '../responsive/breakpoints.dart';
import '../responsive/touch.dart';
import '../router/app_router.dart';
import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_animations.dart';
import 'app_shell_scope.dart';
import 'lingo_desk_icon.dart';
import 'lingo_desk_mark.dart';
import 'lingo_desk_toast.dart';

/// Width of the sidebar with its labels showing.
const double kSidebarWidth = 284;

/// Width of the sidebar as an icon-only rail.
const double kSidebarRailWidth = 72;

/// The two halves of the primary navigation.
///
/// [workspace] is what you do to translations; [settings] is what you
/// configure once and leave alone. The split is what lets the sidebar
/// title its groups, and what lets a phone collapse the second one into a
/// single entry.
enum NavGroup {
  workspace('Workspace'),
  settings('Settings');

  const NavGroup(this.title);

  final String title;
}

/// One place in the primary navigation.
///
/// Held as data rather than built inline, so the sidebar, the rail and the
/// phone's bottom bar all render the same destinations from one list
/// instead of three that have to be kept in step.
class AppDestination {
  const AppDestination({
    required this.label,
    required this.icon,
    required this.group,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final NavGroup group;

  /// Whether the current route belongs to this destination.
  final bool Function(String location) isActive;

  final void Function(BuildContext context) onTap;
}

/// Everywhere the shell navigates to.
///
/// Settings is a group of panes rather than one page with a tab bar: each
/// pane is a row here, so no destination in the app is more than one click
/// away and the rail is the only navigation the settings screens need.
const List<AppDestination> kAppDestinations = [
  AppDestination(
    label: 'Dashboard',
    icon: HugeIcons.strokeRoundedDashboardSquare01,
    group: NavGroup.workspace,
    isActive: _isDashboard,
    onTap: _goDashboard,
  ),
  AppDestination(
    label: 'Apps',
    icon: HugeIcons.strokeRoundedFolder02,
    group: NavGroup.workspace,
    isActive: _isApps,
    onTap: _goApps,
  ),
  AppDestination(
    label: 'Import',
    icon: HugeIcons.strokeRoundedFileUpload,
    group: NavGroup.workspace,
    isActive: _isImport,
    onTap: openImportProject,
  ),
  AppDestination(
    label: 'Profile',
    icon: HugeIcons.strokeRoundedUserCircle,
    group: NavGroup.settings,
    isActive: _isProfile,
    onTap: _goProfile,
  ),
  AppDestination(
    label: 'Appearance',
    icon: HugeIcons.strokeRoundedPaintBoard,
    group: NavGroup.settings,
    isActive: _isAppearance,
    onTap: _goAppearance,
  ),
  AppDestination(
    label: 'Languages',
    icon: HugeIcons.strokeRoundedLanguageSquare,
    group: NavGroup.settings,
    isActive: _isLanguages,
    onTap: _goLanguages,
  ),
  // Keys are a setting you manage, not a workspace task — and putting
  // them here means the old "AI" settings tab has exactly one successor.
  AppDestination(
    label: 'AI providers',
    icon: HugeIcons.strokeRoundedSparkles,
    group: NavGroup.settings,
    isActive: _isAiProviders,
    onTap: _goAiProviders,
  ),
];

/// What the phone's bottom bar carries.
///
/// Seven destinations will not fit along a phone's bottom edge, so the
/// settings group collapses to a single entry that opens its first pane;
/// [SettingsPaneSwitcher] offers the rest once you are there.
const List<AppDestination> kBottomNavDestinations = [
  AppDestination(
    label: 'Dashboard',
    icon: HugeIcons.strokeRoundedDashboardSquare01,
    group: NavGroup.workspace,
    isActive: _isDashboard,
    onTap: _goDashboard,
  ),
  AppDestination(
    label: 'Apps',
    icon: HugeIcons.strokeRoundedFolder02,
    group: NavGroup.workspace,
    isActive: _isApps,
    onTap: _goApps,
  ),
  AppDestination(
    label: 'Import',
    icon: HugeIcons.strokeRoundedFileUpload,
    group: NavGroup.workspace,
    isActive: _isImport,
    onTap: openImportProject,
  ),
  AppDestination(
    label: 'Settings',
    icon: HugeIcons.strokeRoundedSettings01,
    group: NavGroup.settings,
    isActive: _isAnySettings,
    onTap: _goProfile,
  ),
];

bool _isDashboard(String location) => location == AppRoutes.dashboard;

// The editor and per-app pages hang off Apps; uploading into an app
// belongs to Import.
bool _isApps(String location) =>
    location.startsWith(AppRoutes.apps) && !location.endsWith('/upload');

bool _isImport(String location) =>
    location == AppRoutes.importProject || location.endsWith('/upload');

bool _isAiProviders(String location) => location == AppRoutes.aiProviders;

bool _isProfile(String location) => location == AppRoutes.settingsProfile;

bool _isAppearance(String location) => location == AppRoutes.settingsAppearance;

bool _isLanguages(String location) => location == AppRoutes.settingsLanguages;

/// Any pane in the settings group — what the phone's single entry lights
/// up for.
bool _isAnySettings(String location) =>
    location.startsWith(AppRoutes.settings) || _isAiProviders(location);

void _goDashboard(BuildContext context) => context.go(AppRoutes.dashboard);
void _goApps(BuildContext context) => context.go(AppRoutes.apps);
void _goAiProviders(BuildContext context) => context.go(AppRoutes.aiProviders);
void _goProfile(BuildContext context) => context.go(AppRoutes.settingsProfile);
void _goAppearance(BuildContext context) =>
    context.go(AppRoutes.settingsAppearance);
void _goLanguages(BuildContext context) =>
    context.go(AppRoutes.settingsLanguages);

/// Persistent frame around every signed-in page: the navigation, and the
/// routed page beside or above it.
///
/// The nav takes the shape the window can carry — a bottom bar on a phone,
/// an icon rail on a tablet, the full labelled sidebar on a desktop
/// window.
///
/// Owns the single [AppManagementBloc] instance for the whole shell, so
/// the dashboard, the apps page and the sidebar's app chooser all read the
/// same overviews and one load serves them all.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.location, required this.child});

  /// Current route path, used to highlight the active destination.
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
      // The shell owns the only AppManagementBloc, so one listener here
      // toasts its outcomes for every page below — the dashboard, the
      // apps table and the sidebar all get feedback for free.
      child: BlocListener<AppManagementBloc, AppManagementState>(
        listenWhen: (previous, current) =>
            current is AppManagementLoaded && current.notice != null,
        listener: (context, state) =>
            context.showToast((state as AppManagementLoaded).notice!),
        child: ResponsiveBuilder(
          builder: (context, size, constraints) {
            // A phone puts the nav under the thumb; anything wider keeps
            // it down the side, labelled once the window can spare the
            // 284px without squeezing the page beside it.
            final useBottomBar = size.isCompact;
            final collapsed = size.isBelow(WindowSizeClass.large);
            final sidebarWidth = useBottomBar
                ? 0.0
                : (collapsed ? kSidebarRailWidth : kSidebarWidth);

            return AppShellScope(
              // The rail is always on screen, and the bottom bar replaces
              // the drawer outright, so nothing reaches for one any more.
              hasDrawer: false,
              openDrawer: _openDrawer,
              sizeClass: size,
              contentSizeClass: WindowSizeClass.fromWidth(
                constraints.maxWidth - sidebarWidth,
              ),
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: tokens.background,
                bottomNavigationBar: useBottomBar
                    ? AppBottomNav(location: widget.location)
                    : null,
                body: Row(
                  children: [
                    if (!useBottomBar)
                      AppSidebar(
                        location: widget.location,
                        collapsed: collapsed,
                      ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Primary navigation on a phone: the workspace destinations plus one
/// entry for the whole settings group, along the bottom edge where a
/// thumb can reach them.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final selected = kBottomNavDestinations.indexWhere(
      (destination) => destination.isActive(location),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.sidebar,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: tokens.active,
        height: kTouchTarget + 16,
        // Four labels at once is a lot of type along a phone's bottom
        // edge; naming only the one you are on keeps the bar quiet
        // without leaving any destination unnamed when you reach it.
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        // A route the nav has no destination for — the editor, an app's
        // settings — must not light one up at random.
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (index) =>
            kBottomNavDestinations[index].onTap(context),
        destinations: [
          for (final destination in kBottomNavDestinations)
            NavigationDestination(
              icon: LingoDeskIcon(
                destination.icon,
                size: 22,
                color: tokens.muted,
              ),
              selectedIcon: LingoDeskIcon(
                destination.icon,
                size: 22,
                color: tokens.accent,
              ),
              label: destination.label,
            ),
        ],
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

  /// Called after any item is activated; a drawer would use it to close.
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    final width = collapsed ? kSidebarRailWidth : kSidebarWidth;

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
                    padding: collapsed
                        ? const EdgeInsets.only(bottom: 18)
                        : const EdgeInsets.fromLTRB(8, 8, 8, 20),
                    child: LingoDeskMark(
                      size: collapsed ? 28 : 34,
                      reversed: tokens.isDark,
                      showWordmark: !collapsed,
                    ),
                  ),
                  // Seven rows plus two headings outgrow a short window,
                  // so the nav scrolls and the footer stays put rather
                  // than the whole column overflowing.
                  Expanded(
                    child: SingleChildScrollView(
                      child: _SidebarSection(
                        collapsed: collapsed,
                        location: location,
                        onItemTap: onItemTap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SidebarFooter(
                    collapsed: collapsed,
                    onTap: () {
                      context.go(AppRoutes.settingsProfile);
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

/// The rail's rows, split into titled groups.
///
/// At full width each group is announced by its name; in the icon rail
/// there is no room for words, so the same break is drawn as a hairline —
/// the grouping survives the collapse, only its label doesn't.
class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.collapsed,
    required this.location,
    this.onItemTap,
  });

  final bool collapsed;
  final String location;
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final headingStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: tokens.muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, group) in NavGroup.values.indexed) ...[
          if (!collapsed)
            Padding(
              padding: EdgeInsets.fromLTRB(10, index == 0 ? 0 : 18, 10, 8),
              child: Text(group.title.toUpperCase(), style: headingStyle),
            )
          // The first group needs no rule above it — the mark already
          // separates it from the top of the rail.
          else if (index != 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Divider(color: tokens.border, height: 1, thickness: 1),
            ),
          for (final destination in kAppDestinations.where(
            (destination) => destination.group == group,
          ))
            _SidebarItem(
              destination: destination,
              isActive: destination.isActive(location),
              collapsed: collapsed,
              onItemTap: onItemTap,
            ),
        ],
      ],
    );
  }
}

/// A nav row that answers the pointer before it is clicked: the fill
/// warms on hover, the label and icon come up to full contrast, and the
/// active item grows a teal bar against the rail's inner edge.
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.destination,
    required this.isActive,
    required this.collapsed,
    this.onItemTap,
  });

  final AppDestination destination;
  final bool isActive;
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
    final destination = widget.destination;
    final collapsed = widget.collapsed;
    final foreground = widget.isActive || _hovered
        ? tokens.foreground
        : tokens.muted;
    final background = widget.isActive
        ? tokens.active
        : _hovered
        ? tokens.active.withValues(alpha: 0.6)
        : Colors.transparent;

    final row = AnimatedContainer(
      duration: LingoDeskMotion.fast,
      curve: LingoDeskMotion.curve,
      // A rail on a touch screen is reached with a thumb, so the rows
      // grow to a finger's size there and stay tight under a pointer.
      height: isTouchPlatform ? kTouchTarget : 40,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedTint(
        color: foreground,
        builder: (context, tint) {
          final icon = LingoDeskIcon(destination.icon, size: 18, color: tint);

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
                    destination.label,
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
          height: widget.isActive ? 18 : 0,
          decoration: BoxDecoration(
            color: tokens.accent,
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
          onTap: () {
            destination.onTap(context);
            widget.onItemTap?.call();
          },
          borderRadius: BorderRadius.circular(12),
          // The rail's own tint already reads as hover; Material's would
          // stack a second wash on top of it.
          hoverColor: Colors.transparent,
          child: collapsed
              ? Tooltip(message: destination.label, child: content)
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
            // brand/onBrand rather than the accent: this is a solid tile
            // with text on it, and the graphite variant's dark accent is
            // near-white.
            color: tokens.brand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            settings.profileInitials,
            style: TextStyle(
              color: tokens.onBrand,
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
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHitTarget),
                child: Center(child: avatar),
              ),
            ),
          );
        }

        final subtitle = settings.profileEmail.isEmpty
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
