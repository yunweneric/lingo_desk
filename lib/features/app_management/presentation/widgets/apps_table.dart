import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_menu.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../domain/entities/app_overview.dart';
import '../app_actions.dart';
import '../bloc/app_management_state.dart';

/// Most language badges a row shows inline before the rest move into the
/// collapsible section. Four keeps every row exactly one line tall; a
/// narrow window fits fewer and folds the rest away instead of wrapping.
const int _maxInlineLanguages = 4;

/// Horizontal padding and border a [WorkspaceBadge] adds around its
/// label, and the gap between two badges — the two numbers that turn a
/// measured label into the width a badge occupies in the row.
const double _badgeChrome = 20;
const double _badgeGap = 6;

/// Floors for a measured badge and for the overflow chip, in the row's
/// 12px bold face.
///
/// The row has to know how many badges fit before it lays any of them
/// out, and the measurement below can come back short: the theme's face
/// is fetched at runtime, so a [TextPainter] built before it resolves
/// measures the fallback and reports a narrower pill than the one that
/// finally paints. Taking the wider of measurement and floor stops a
/// short measurement packing in one badge too many, and still lets a
/// genuinely wider face push the count down.
const double _minBadgeSlot = 46;
const double _minChipSlot = 56;

/// Width of a pill holding [label] in [style], including the badge's own
/// padding and border.
double _pillWidth(String label, TextStyle? style, TextScaler textScaler) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();
  return painter.width + _badgeChrome;
}

/// Width of the leading expander column, shared by header and rows so the
/// columns stay aligned whether or not a row can expand.
const double _expanderColumn = 30;

/// Gutter the trailing row menu sits in, reserved in the header too.
const double _rowMenuWidth = 32;

/// Every app with its file counters, coverage and status.
class AppsTable extends StatelessWidget {
  const AppsTable({super.key, required this.state});

  final AppManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final overviews = state.filteredOverviews;

    return ResponsiveBuilder(
      builder: (context, size, constraints) {
        // Seven columns across a phone gives the app's own name about
        // 76px and the status badge 38 — present, but unreadable. Below
        // the compact boundary each app becomes a card instead.
        final asCards = size.isCompact;

        // The table fills the pane rather than scrolling sideways, so how
        // many language badges fit inline is a function of the width the
        // Languages column ends up with: flex 3 of 16 of the row, less
        // the surface border, the row padding, the leading expander and
        // the trailing menu.
        final rowWidth =
            constraints.maxWidth - 42 - _expanderColumn - _rowMenuWidth;
        final languagesWidth = rowWidth * 3 / 16;
        // Language codes are two letters, so one measurement covers every
        // badge; the chip is reserved at its widest label.
        final badgeStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        );
        final textScaler = MediaQuery.textScalerOf(context);
        final badgeSlot = math.max(
          _minBadgeSlot,
          _pillWidth('WW', badgeStyle, textScaler) + _badgeGap,
        );
        final chipSlot = math.max(
          _minChipSlot,
          math.max(
                _pillWidth('+99', badgeStyle, textScaler),
                _pillWidth('Less', badgeStyle, textScaler),
              ) +
              _badgeGap,
        );
        // Zero is a real answer: a pane narrow enough to fit no badge
        // still fits the chip, and every language is one click away in
        // the section below the row.
        final inlineLimit = ((languagesWidth - chipSlot) / badgeSlot)
            .floor()
            .clamp(0, _maxInlineLanguages);

        return WorkspaceSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: WorkspaceCardHeader(
                        title: 'Apps',
                        subtitle: state.query.trim().isEmpty
                            ? 'Current localization workspaces'
                            : '${overviews.length} of '
                                  '${state.overviews.length} apps match '
                                  '"${state.query.trim()}"',
                        icon: HugeIcons.strokeRoundedFolder02,
                      ),
                    ),
                    if (!asCards)
                      TextButton.icon(
                        onPressed: () => openCreateApp(context),
                        icon: const LingoDeskIcon(
                          HugeIcons.strokeRoundedAdd01,
                          size: 17,
                        ),
                        label: const Text('New app'),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: tokens.border),
              if (!asCards) ...[
                _TableHeader(tokens: tokens),
                Divider(height: 1, color: tokens.border),
              ],
              if (overviews.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'No apps match your search.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                  ),
                )
              else
                for (var index = 0; index < overviews.length; index++) ...[
                  FadeSlideIn.staggered(
                    index: index,
                    child:
                        asCards
                            ? _AppCard(overview: overviews[index])
                            : _AppRow(
                              overview: overviews[index],
                              inlineLimit: inlineLimit,
                            ),
                  ),
                  if (index != overviews.length - 1)
                    Divider(height: 1, color: tokens.border),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.tokens});

  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: _expanderColumn),
          _HeaderCell('App', flex: 4, tokens: tokens),
          _HeaderCell('Languages', flex: 3, tokens: tokens),
          _HeaderCell('Files', flex: 2, tokens: tokens),
          _HeaderCell('Progress', flex: 3, tokens: tokens),
          _HeaderCell('Status', flex: 2, tokens: tokens),
          _HeaderCell('Updated', flex: 2, tokens: tokens),
          const SizedBox(width: _rowMenuWidth),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex, required this.tokens});

  final String label;
  final int flex;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// One app in the table. The whole row is a link into the editor, so it
/// warms under the pointer and slides a teal marker in against its left
/// edge — the same language the sidebar uses for "you are here".
///
/// Apps with more target languages than fit on one line keep the row a
/// single line tall and move the rest into a section that opens below,
/// off the chevron at the start of the row.
class _AppRow extends StatefulWidget {
  const _AppRow({required this.overview, required this.inlineLimit});

  final AppOverview overview;

  /// Language badges that fit on the row at the current width.
  final int inlineLimit;

  @override
  State<_AppRow> createState() => _AppRowState();
}

class _AppRowState extends State<_AppRow> {
  /// Hover lives in a notifier rather than in [State] so that moving the
  /// pointer across the row repaints the tint without rebuilding the
  /// row's contents — the trailing overflow menu among them, and you
  /// have to cross the row to reach it.
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final overview = widget.overview;
    final app = overview.app;
    final status = appStatusOf(overview);
    final languages = app.targetLanguages;
    final overflow = languages.length - widget.inlineLimit;
    final canExpand = overflow > 0;

    return ValueListenableBuilder<bool>(
      valueListenable: _hovered,
      // `row` is built once per real change and handed through untouched,
      // so hovering never reaches the menu anchor inside it.
      builder: (context, hovered, row) {
        return AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: hovered || _expanded
                    ? LingoDeskColors.brandTeal
                    : Colors.transparent,
              ),
            ),
          ),
          child: row,
        );
      },
      child: Column(
        children: [
          MouseRegion(
            onEnter: (_) => _hovered.value = true,
            onExit: (_) => _hovered.value = false,
            child: InkWell(
              onTap: () => openEditor(context, overview),
              hoverColor: Colors.transparent,
              child: ValueListenableBuilder<bool>(
                valueListenable: _hovered,
                builder: (context, hovered, content) {
                  return AnimatedContainer(
                    duration: LingoDeskMotion.fast,
                    curve: LingoDeskMotion.curve,
                    // Transparent, never null: a null colour makes
                    // Container drop its ColoredBox, which changes the
                    // shape of the tree and re-inflates everything below
                    // it — including the overflow menu's anchor, whose
                    // open menu dies with it.
                    color: hovered
                        ? tokens.active.withValues(alpha: 0.6)
                        : Colors.transparent,
                    padding: const EdgeInsets.fromLTRB(17, 14, 20, 14),
                    child: content,
                  );
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: _expanderColumn,
                      child: canExpand
                          ? _ExpanderButton(
                              expanded: _expanded,
                              hovered: _hovered,
                              tokens: tokens,
                              onTap: _toggle,
                            )
                          : null,
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          AppAvatar(
                            name: app.name,
                            initials: app.initials,
                            iconImage: app.iconImage,
                            size: 34,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${app.sourceLanguage}.json - '
                                  '${overview.keyCount} keys',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: LingoDeskTheme.codeStyle.copyWith(
                                    color: tokens.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          for (final language in languages.take(
                            widget.inlineLimit,
                          )) ...[
                            WorkspaceBadge(
                              label: language.toUpperCase(),
                              color: tokens.muted,
                            ),
                            const SizedBox(width: _badgeGap),
                          ],
                          if (canExpand)
                            // Loose so the label clips rather than
                            // overflows if the column is squeezed below
                            // even the chip's width.
                            Flexible(
                              child: _OverflowChip(
                                count: overflow,
                                expanded: _expanded,
                                tokens: tokens,
                                onTap: _toggle,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${overview.completeFileCount}/'
                            '${overview.fileCount}',
                            style: LingoDeskTheme.codeStyle.copyWith(
                              color: tokens.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'complete',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: tokens.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: WorkspaceProgressBar(
                        value: overview.progress,
                        isComplete: overview.isComplete,
                        showPercentage: true,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: WorkspaceBadge(
                          label: status.label,
                          color: status.color,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormatter.relative(overview.lastActivity),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                      ),
                    ),
                    // Pinned to the gutter the header reserves: the
                    // badge count is derived from the flex space left
                    // over, so this must not vary with the icon.
                    //
                    // Kept at full strength rather than fading in on
                    // hover: it is the only way into this row's settings
                    // and delete, and a control you have to hunt for is a
                    // control that is hard to hit.
                    SizedBox(
                      width: _rowMenuWidth,
                      child: _AppRowMenu(overview: overview),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: LingoDeskMotion.standard,
            curve: LingoDeskMotion.curve,
            alignment: Alignment.topCenter,
            child: _expanded && canExpand
                ? _LanguagePanel(overview: overview, tokens: tokens)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The chevron at the start of an expandable row. One arrow that turns,
/// rather than two that swap — the rotation is what says "this opens".

/// One app on a phone: everything the row's seven columns carry, stacked.
///
/// No expander here — a card has the width to show every language badge,
/// so there is nothing folded away for a chevron to open.
class _AppCard extends StatelessWidget {
  const _AppCard({required this.overview});

  final AppOverview overview;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final app = overview.app;
    final status = appStatusOf(overview);

    return InkWell(
      onTap: () => openEditor(context, overview),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  name: app.name,
                  initials: app.initials,
                  iconImage: app.iconImage,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${app.sourceLanguage}.json - '
                        '${overview.keyCount} keys',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LingoDeskTheme.codeStyle.copyWith(
                          color: tokens.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _AppRowMenu(overview: overview),
              ],
            ),
            const SizedBox(height: 12),
            WorkspaceProgressBar(
              value: overview.progress,
              isComplete: overview.isComplete,
              showPercentage: true,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: _badgeGap,
              runSpacing: _badgeGap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                WorkspaceBadge(label: status.label, color: status.color),
                for (final language in app.targetLanguages)
                  WorkspaceBadge(
                    label: language.toUpperCase(),
                    color: tokens.muted,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${overview.completeFileCount}/${overview.fileCount} files '
              'complete - ${DateFormatter.relative(overview.lastActivity)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpanderButton extends StatelessWidget {
  const _ExpanderButton({
    required this.expanded,
    required this.hovered,
    required this.tokens,
    required this.onTap,
  });

  final bool expanded;

  /// The row's hover state. Listened to here rather than passed as a
  /// bool, so brightening this arrow does not rebuild the rest of the
  /// row — see [_AppRowState].
  final ValueListenable<bool> hovered;

  final LingoDeskTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: expanded ? 'Hide languages' : 'Show all languages',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: LingoDeskMotion.standard,
              curve: LingoDeskMotion.curve,
              child: ValueListenableBuilder<bool>(
                valueListenable: hovered,
                builder: (context, isHovered, _) {
                  return LingoDeskIcon(
                    HugeIcons.strokeRoundedArrowRight01,
                    size: 16,
                    color: expanded || isHovered
                        ? tokens.foreground
                        : tokens.muted,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The `+N` pill standing in for the languages that did not fit. It opens
/// the same section as the chevron, so either end of the row works.
class _OverflowChip extends StatelessWidget {
  const _OverflowChip({
    required this.count,
    required this.expanded,
    required this.tokens,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final LingoDeskTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = expanded ? LingoDeskColors.brandTeal : tokens.foreground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withAlpha(78)),
        ),
        child: Text(
          expanded ? 'Less' : '+$count',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// The collapsible section under a row: every target language with what
/// it is still missing, so the overflow is worth opening rather than
/// just the badges that did not fit.
class _LanguagePanel extends StatelessWidget {
  const _LanguagePanel({required this.overview, required this.tokens});

  final AppOverview overview;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    final languages = overview.app.targetLanguages;

    return Container(
      width: double.infinity,
      color: tokens.active.withValues(alpha: 0.35),
      padding: const EdgeInsets.fromLTRB(47, 14, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${languages.length} target languages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final language in languages)
                _LanguageTile(
                  code: language,
                  keyCount: overview.keyCount,
                  missing: overview.missingByLanguage[language] ?? 0,
                  tokens: tokens,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.keyCount,
    required this.missing,
    required this.tokens,
  });

  final String code;
  final int keyCount;
  final int missing;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isComplete = keyCount > 0 && missing == 0;
    final progress = keyCount == 0 ? 0.0 : (keyCount - missing) / keyCount;

    return Container(
      width: 232,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                SupportedLanguages.flagOf(code),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  SupportedLanguages.nameOf(code),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(width: 6),
              WorkspaceBadge(label: code.toUpperCase(), color: tokens.muted),
            ],
          ),
          const SizedBox(height: 10),
          WorkspaceProgressBar(
            value: progress,
            isComplete: isComplete,
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            isComplete ? 'Complete' : '$missing missing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isComplete ? LingoDeskColors.complete : tokens.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRowMenu extends StatelessWidget {
  const _AppRowMenu({required this.overview});

  final AppOverview overview;

  @override
  Widget build(BuildContext context) {
    return LingoDeskMenuButton<String>(
      items: const [
        LingoDeskMenuItem(
          value: 'editor',
          label: 'Open editor',
          icon: HugeIcons.strokeRoundedTableRowsSplit,
        ),
        LingoDeskMenuItem(
          value: 'settings',
          label: 'Settings',
          icon: HugeIcons.strokeRoundedSettings01,
        ),
        LingoDeskMenuItem(
          value: 'upload',
          label: 'Upload files',
          icon: HugeIcons.strokeRoundedFileUpload,
        ),
        LingoDeskMenuItem.divider(),
        LingoDeskMenuItem(
          value: 'delete',
          label: 'Delete app',
          icon: HugeIcons.strokeRoundedDelete02,
          destructive: true,
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case 'editor':
            openEditor(context, overview);
          case 'settings':
            openAppSettings(context, overview);
          case 'upload':
            openFileUpload(context, overview);
          case 'delete':
            confirmDeleteApp(context, overview);
        }
      },
    );
  }
}
