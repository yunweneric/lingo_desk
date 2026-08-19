import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/workspace_card.dart';
import '../../core/widgets/workspace_scaffold.dart';
import 'preview_chrome.dart';
import 'preview_workspace.dart';
import '../../core/localization/export.dart';

/// Coverage, key counts and language health — recomputed from whatever the
/// editor pane has been filled in with, so the two screens never disagree.
class PreviewDashboardPane extends StatelessWidget {
  const PreviewDashboardPane({
    super.key,
    required this.workspace,
    this.onNavigate,
  });

  final PreviewWorkspace workspace;
  final ValueChanged<PreviewScreen>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final missing = workspace.totalMissing;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PreviewBreadcrumb(
            segments: [
              LocaleKeys.navGroupWorkspace.tr(),
              LocaleKeys.navDashboard.tr(),
            ],
            actions: const [_ThemePill()],
          ),
          const SizedBox(height: 16),
          _HeaderCard(workspace: workspace),
          const SizedBox(height: 12),
          SizedBox(
            height: 122,
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: LocaleKeys.navApps.tr(),
                    value: PreviewWorkspace.apps.length.toString(),
                    detail: LocaleKeys.dashboardMetricLocalWorkspace.tr(),
                    icon: HugeIcons.strokeRoundedFolder02,
                    onTap: () => onNavigate?.call(PreviewScreen.projects),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: LocaleKeys.dashboardMetricTotalKeys.tr(),
                    value: workspace.entries.length.toString(),
                    detail: 'Storefront · en.json',
                    icon: HugeIcons.strokeRoundedKey01,
                    onTap: () => onNavigate?.call(PreviewScreen.editor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: LocaleKeys.dashboardMetricCoverage.tr(),
                    value: '${(workspace.coverage * 100).round()}%',
                    detail: LocaleKeys.dashboardMetricTargetLocales.plural(
                      PreviewWorkspace.locales.length,
                    ),
                    icon: HugeIcons.strokeRoundedChartHistogram,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: LocaleKeys.dashboardMetricMissing.tr(),
                    value: missing.toString(),
                    detail: missing == 0
                        ? LocaleKeys.dashboardMetricAllClear.tr()
                        : LocaleKeys.dashboardMetricNeedsReview.tr(),
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    isPositive: missing == 0,
                    onTap: () => onNavigate?.call(PreviewScreen.editor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: _CoverageCard(workspace: workspace)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: _LanguageHealthCard(workspace: workspace),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the real theme-mode switcher in the page header.
class _ThemePill extends StatelessWidget {
  const _ThemePill();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          LingoDeskIcon(
            tokens.isDark
                ? HugeIcons.strokeRoundedMoon02
                : HugeIcons.strokeRoundedSun03,
            size: 16,
            color: tokens.muted,
          ),
          const SizedBox(width: 8),
          Text(
            LocaleKeys.commonThemeSystem.tr(),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: tokens.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.workspace});

  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final missing = workspace.totalMissing;

    return WorkspaceSurface(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.dashboardTitle.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 27,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleKeys.dashboardSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.muted,
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Capped like the real header's stats block, so the tiles wrap
          // to a second line rather than squeezing the title.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                WorkspaceMetaTile(
                  label: LocaleKeys.navApps.tr(),
                  value: PreviewWorkspace.apps.length.toString(),
                  icon: HugeIcons.strokeRoundedFolder02,
                ),
                WorkspaceMetaTile(
                  label: LocaleKeys.dashboardStatKeys.tr(),
                  value: workspace.entries.length.toString(),
                  icon: HugeIcons.strokeRoundedKey01,
                ),
                WorkspaceMetaTile(
                  label: LocaleKeys.dashboardStatLocales.tr(),
                  value: PreviewWorkspace.locales.length.toString(),
                  icon: HugeIcons.strokeRoundedLanguageSquare,
                ),
                WorkspaceBadge(
                  label: missing == 0
                      ? LocaleKeys.dashboardMetricAllClear.tr()
                      : LocaleKeys.landingPreviewMissingStrings.plural(missing),
                  color: missing == 0
                      ? LingoDeskColors.complete
                      : LingoDeskColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatefulWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.isPositive = true,
    this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final List<List<dynamic>> icon;
  final bool isPositive;
  final VoidCallback? onTap;

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedSlide(
          offset: _hovered && widget.onTap != null
              ? const Offset(0, -0.016)
              : Offset.zero,
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          child: Container(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered && widget.onTap != null
                    ? tokens.brandFillBorder
                    : tokens.border,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    LingoDeskIcon(widget.icon, color: tokens.muted, size: 18),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.value,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 30),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    LingoDeskIcon(
                      widget.isPositive
                          ? HugeIcons.strokeRoundedArrowUpRight02
                          : HugeIcons.strokeRoundedArrowDownRight02,
                      size: 16,
                      color: widget.isPositive
                          ? LingoDeskColors.complete
                          : LingoDeskColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.detail,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: tokens.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({required this.workspace});

  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkspaceCardHeader(
            title: LocaleKeys.dashboardCoverageTitle.tr(),
            subtitle: LocaleKeys.dashboardCoverageSubtitle.tr(),
            icon: HugeIcons.strokeRoundedChartArea,
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < PreviewWorkspace.apps.length; i++) ...[
                  Expanded(
                    child: _ChartBar(
                      app: PreviewWorkspace.apps[i],
                      // Storefront is the app the editor is open on, so
                      // its bar tracks the live numbers.
                      value: i == 0
                          ? workspace.coverage
                          : PreviewWorkspace.apps[i].progress,
                      index: i,
                    ),
                  ),
                  if (i != PreviewWorkspace.apps.length - 1)
                    const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: tokens.border),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.dashboardCoverageSummary.tr(
              namedArgs: {
                'translated': '${workspace.totalTranslated}',
                'missing': '${workspace.totalMissing}',
              },
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// One column of the coverage chart: grows up from the axis on first
/// paint and brightens with a tooltip under the pointer, exactly as the
/// real chart does.
class _ChartBar extends StatefulWidget {
  const _ChartBar({
    required this.app,
    required this.value,
    required this.index,
  });

  final PreviewApp app;
  final double value;
  final int index;

  @override
  State<_ChartBar> createState() => _ChartBarState();
}

class _ChartBarState extends State<_ChartBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: '${widget.app.name} — ${(widget.value * 100).round()}%',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: widget.value.clamp(0.02, 1)),
                  duration:
                      LingoDeskMotion.slow +
                      LingoDeskMotion.delayFor(widget.index),
                  curve: LingoDeskMotion.entrance,
                  builder: (context, height, _) => FractionallySizedBox(
                    heightFactor: height,
                    widthFactor: 1,
                    child: AnimatedContainer(
                      duration: LingoDeskMotion.fast,
                      curve: LingoDeskMotion.curve,
                      decoration: BoxDecoration(
                        color: _hovered
                            ? tokens.accent
                            : tokens.accent.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.app.initials,
              style: LingoDeskTheme.codeStyle.copyWith(
                color: _hovered ? tokens.foreground : tokens.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageHealthCard extends StatelessWidget {
  const _LanguageHealthCard({required this.workspace});

  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final behind = PreviewWorkspace.locales
        .where((locale) => workspace.missingIn(locale) > 0)
        .toList();

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WorkspaceCardHeader(
            title: LocaleKeys.dashboardHealthTitle.tr(),
            subtitle: LocaleKeys.dashboardHealthSubtitle.tr(),
            icon: HugeIcons.strokeRoundedLanguageSquare,
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < PreviewWorkspace.locales.length; i++) ...[
            _LanguageProgress(
              locale: PreviewWorkspace.locales[i],
              workspace: workspace,
            ),
            if (i != PreviewWorkspace.locales.length - 1)
              const SizedBox(height: 16),
          ],
          const Spacer(),
          Divider(color: tokens.border),
          const SizedBox(height: 14),
          Row(
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedClock03,
                color: tokens.muted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  behind.isEmpty
                      ? LocaleKeys.landingPreviewAllTranslated.tr()
                      : LocaleKeys.dashboardHealthNextReview.tr(
                          namedArgs: {
                            'name':
                                '${behind.first.toUpperCase()} · Storefront',
                          },
                        ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageProgress extends StatelessWidget {
  const _LanguageProgress({required this.locale, required this.workspace});

  final String locale;
  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final missing = workspace.missingIn(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              locale.toUpperCase(),
              style: LingoDeskTheme.codeStyle.copyWith(
                color: tokens.foreground,
              ),
            ),
            const Spacer(),
            Text(
              missing == 0
                  ? LocaleKeys.appsStatusComplete.tr()
                  : LocaleKeys.commonMissingCount.plural(missing),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WorkspaceProgressBar(
          value: workspace.progressIn(locale),
          isComplete: missing == 0,
        ),
      ],
    );
  }
}
