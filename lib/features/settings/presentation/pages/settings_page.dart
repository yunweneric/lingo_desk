import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../widgets/settings_appearance_card.dart';
import '../widgets/settings_defaults_card.dart';
import '../widgets/settings_language_card.dart';
import '../widgets/settings_profile_card.dart';

/// Workspace preferences: profile, theme, interface language and the
/// defaults applied to new apps, organized in tabs. Everything writes
/// straight through [AppSettingsController] to SharedPreferences.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  final AppSettingsController _settings = getIt<AppSettingsController>();

  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(_onTabChanged);

  @override
  void dispose() {
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging || _tabs.index != _shownIndex) {
      setState(() => _shownIndex = _tabs.index);
    }
  }

  int _shownIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return ColoredBox(
      color: tokens.background,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) {
            return Column(
              children: [
                const WorkspacePageHeader(
                  breadcrumb: [Crumb.workspace, Crumb('Settings')],
                ),
                _SettingsTabStrip(
                  child: _SettingsTabBar(tokens: tokens, controller: _tabs),
                ),
                Expanded(
                  // Tabs cross-fade instead of sliding: swiping between them
                  // would fight the scrollable content on desktop.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    layoutBuilder:
                        (currentChild, previousChildren) => Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.topLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_shownIndex),
                      child: _tabContent(_shownIndex),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabContent(int index) {
    switch (index) {
      case 0:
        return _SettingsTabContent(
          child: SettingsProfileCard(settings: _settings),
        );
      case 1:
        return _SettingsTabContent(
          child: SettingsAppearanceCard(settings: _settings),
        );
      default:
        return _SettingsTabContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsLanguageCard(settings: _settings),
              const SizedBox(height: 16),
              SettingsDefaultsCard(settings: _settings),
            ],
          ),
        );
    }
  }
}

/// Left-aligns the tab bar on the same gutter as [WorkspacePageHeader],
/// sized to its content rather than the full page width.
class _SettingsTabStrip extends StatelessWidget {
  const _SettingsTabStrip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 780 ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
          child: Align(alignment: Alignment.topLeft, child: child),
        );
      },
    );
  }
}

/// Pill-style tab bar matching the workspace design language.
class _SettingsTabBar extends StatelessWidget {
  const _SettingsTabBar({required this.tokens, required this.controller});

  final LingoDeskTokens tokens;
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.all(4),
      // Keeps the TabBar working even without a Scaffold above the page.
      child: Material(
        type: MaterialType.transparency,
        child: TabBar(
          controller: controller,
          // Sizes each tab to its label so the bar hugs its content
          // instead of stretching across the page.
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 0,
          padding: EdgeInsets.zero,
          labelPadding: EdgeInsets.zero,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: tokens.active,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: tokens.border),
          ),
          labelColor: tokens.foreground,
          unselectedLabelColor: tokens.muted,
          labelStyle: Theme.of(context).textTheme.labelLarge,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: const [
            _SettingsTab(
              label: 'Profile',
              icon: HugeIcons.strokeRoundedUserCircle,
            ),
            _SettingsTab(
              label: 'Appearance',
              icon: HugeIcons.strokeRoundedPaintBoard,
            ),
            _SettingsTab(
              label: 'Languages',
              icon: HugeIcons.strokeRoundedLanguageSquare,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.label, required this.icon});

  final String label;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LingoDeskIcon(icon, size: 17),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Shared scroll + gutters for each tab's content, stretched to the
/// full width of the workspace pane.
class _SettingsTabContent extends StatelessWidget {
  const _SettingsTabContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth < 780 ? 16.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 28),
          child: SizedBox(width: double.infinity, child: child),
        );
      },
    );
  }
}
