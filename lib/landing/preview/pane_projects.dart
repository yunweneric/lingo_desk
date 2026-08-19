import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/languages.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/workspace_card.dart';
import '../../core/widgets/workspace_scaffold.dart';
import 'preview_chrome.dart';
import 'preview_workspace.dart';
import '../../core/localization/export.dart';

/// One workspace per app, each with its own source language and targets.
///
/// Rows expand to show their locales, and clicking one opens the editor —
/// the same navigation the real table does.
class PreviewProjectsPane extends StatefulWidget {
  const PreviewProjectsPane({
    super.key,
    required this.workspace,
    this.onNavigate,
  });

  final PreviewWorkspace workspace;
  final ValueChanged<PreviewScreen>? onNavigate;

  @override
  State<PreviewProjectsPane> createState() => _PreviewProjectsPaneState();
}

class _PreviewProjectsPaneState extends State<PreviewProjectsPane> {
  String _query = '';
  String? _expanded;

  List<PreviewApp> get _apps {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) {
      return PreviewWorkspace.apps;
    }
    return PreviewWorkspace.apps
        .where((app) => app.name.toLowerCase().contains(needle))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final apps = _apps;
    final overall =
        PreviewWorkspace.apps.fold<double>(
          0,
          (sum, app) => sum + app.progress,
        ) /
        PreviewWorkspace.apps.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PreviewBreadcrumb(
            segments: [
              LocaleKeys.navGroupWorkspace.tr(),
              LocaleKeys.navApps.tr(),
            ],
            actions: [
              SizedBox(
                width: 230,
                child: _AppSearch(
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              PreviewButton(
                label: LocaleKeys.appsImportProject.tr(),
                icon: HugeIcons.strokeRoundedFileImport,
              ),
              PreviewButton(
                label: LocaleKeys.appsNewApp.tr(),
                icon: HugeIcons.strokeRoundedAdd01,
                primary: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          WorkspaceSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: WorkspaceCardHeader(
                        title: LocaleKeys.appsSummaryTitle.tr(),
                        subtitle: LocaleKeys.appsSummarySubtitle.tr(),
                        icon: HugeIcons.strokeRoundedChartHistogram,
                      ),
                    ),
                    WorkspaceBadge(
                      label: '${(overall * 100).round()}% overall',
                      color: LingoDeskColors.complete,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                WorkspaceProgressBar(value: overall, isComplete: false),
                const SizedBox(height: 16),
                Row(
                  children: [
                    WorkspaceMetaTile(
                      label: LocaleKeys.navApps.tr(),
                      value: PreviewWorkspace.apps.length.toString(),
                      icon: HugeIcons.strokeRoundedFolder02,
                      width: 108,
                    ),
                    const SizedBox(width: 8),
                    WorkspaceMetaTile(
                      label: LocaleKeys.dashboardMetricTotalKeys.tr(),
                      value: '428',
                      icon: HugeIcons.strokeRoundedKey01,
                      width: 128,
                    ),
                    const SizedBox(width: 8),
                    WorkspaceMetaTile(
                      label: LocaleKeys.appsSummaryMissingStrings.tr(),
                      value: widget.workspace.totalMissing.toString(),
                      icon: HugeIcons.strokeRoundedAlertCircle,
                      width: 152,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
                border: Border.all(color: tokens.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(LingoDeskTheme.radius - 1),
                child: Column(
                  children: [
                    PreviewTableHeader(
                      cells: [
                        (34, LocaleKeys.appsTableColApp.tr().toUpperCase()),
                        (
                          20,
                          LocaleKeys.appsTableColLanguages.tr().toUpperCase(),
                        ),
                        (14, LocaleKeys.appsTableColFiles.tr().toUpperCase()),
                        (
                          22,
                          LocaleKeys.appsTableColProgress.tr().toUpperCase(),
                        ),
                        (
                          16,
                          LocaleKeys.appsTableColUpdated.tr().toUpperCase(),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        // As in the editor: sized to fit, so the page
                        // keeps the scroll wheel.
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: apps.length,
                        itemBuilder: (context, index) => _AppRow(
                          app: apps[index],
                          expanded: _expanded == apps[index].name,
                          onToggle: () => setState(
                            () => _expanded = _expanded == apps[index].name
                                ? null
                                : apps[index].name,
                          ),
                          onOpen: () =>
                              widget.onNavigate?.call(PreviewScreen.editor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSearch extends StatefulWidget {
  const _AppSearch({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_AppSearch> createState() => _AppSearchState();
}

class _AppSearchState extends State<_AppSearch> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final focused = _focus.hasFocus;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(
          color: focused ? tokens.accent : tokens.border,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          LingoDeskIcon(
            HugeIcons.strokeRoundedSearch01,
            size: 16,
            color: focused ? tokens.accent : tokens.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              focusNode: _focus,
              onChanged: widget.onChanged,
              cursorColor: tokens.accent,
              style: TextStyle(fontSize: 13, color: tokens.foreground),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: LocaleKeys.appsSearchHint.tr(),
                hintStyle: TextStyle(fontSize: 13, color: tokens.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRow extends StatefulWidget {
  const _AppRow({
    required this.app,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
  });

  final PreviewApp app;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final app = widget.app;
    final complete = app.progress >= 1;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        onDoubleTap: widget.onOpen,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          decoration: BoxDecoration(
            color: _hovered || widget.expanded
                ? tokens.active
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: tokens.border),
              left: BorderSide(
                width: 3,
                color: _hovered || widget.expanded
                    ? tokens.accent
                    : Colors.transparent,
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 34,
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tokens.brandFill,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: tokens.brandFillBorder,
                                ),
                              ),
                              child: Text(
                                app.initials,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: tokens.onBrandFill,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    app.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.foreground,
                                    ),
                                  ),
                                  Text(
                                    '${app.sourceFile} · '
                                    '${app.keyCount} keys',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: tokens.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 20,
                        child: Row(
                          children: [
                            for (final locale in app.locales.take(3))
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: _LocaleChip(locale: locale),
                              ),
                            if (app.locales.length > 3)
                              Text(
                                '+${app.locales.length - 3}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: tokens.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 14,
                        child: Text(
                          '${app.filesComplete}/${app.locales.length}',
                          style: LingoDeskTheme.codeStyle.copyWith(
                            color: tokens.foreground,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 22,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: WorkspaceProgressBar(
                            value: app.progress,
                            isComplete: complete,
                            minHeight: 6,
                            showPercentage: true,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 16,
                        child: Text(
                          app.updated,
                          style: TextStyle(fontSize: 12.5, color: tokens.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expanding a row shows the per-locale breakdown, and the
              // way back into the editor.
              AnimatedSize(
                duration: LingoDeskMotion.standard,
                curve: LingoDeskMotion.curve,
                child: widget.expanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(62, 0, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final locale in app.locales)
                                    WorkspaceBadge(
                                      label:
                                          '${SupportedLanguages.flagOf(locale)}'
                                          '  ${locale.toUpperCase()}',
                                      color: complete
                                          ? LingoDeskColors.complete
                                          : tokens.accent,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            PreviewButton(
                              label: LocaleKeys.appsMenuOpenEditor.tr(),
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              onTap: widget.onOpen,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleChip extends StatelessWidget {
  const _LocaleChip({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      width: 30,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.active,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      child: Text(
        locale.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tokens.muted,
        ),
      ),
    );
  }
}
