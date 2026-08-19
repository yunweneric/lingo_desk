import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/constants/languages.dart';
import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import '../../core/widgets/workspace_card.dart';
import 'preview_chrome.dart';
import 'preview_workspace.dart';
import '../../core/localization/export.dart';

/// The workspace: keys down the side, locales across the top.
///
/// The interactive one. Every target cell is a real text field writing
/// into [PreviewWorkspace], the search box and the missing-only toggle
/// really filter, and "AI translate" fills the empty cells — which moves
/// the progress bars here and the coverage numbers on the dashboard.
class PreviewEditorPane extends StatelessWidget {
  const PreviewEditorPane({super.key, required this.workspace});

  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final rows = workspace.visibleEntries;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PreviewBreadcrumb(
            segments: [
              LocaleKeys.navGroupWorkspace.tr(),
              LocaleKeys.navApps.tr(),
              'Storefront',
              LocaleKeys.editorTitle.tr(),
            ],
            actions: [
              PreviewButton(
                label: LocaleKeys.editorAiTranslate.tr(),
                icon: HugeIcons.strokeRoundedSparkles,
                onTap: workspace.totalMissing == 0
                    ? null
                    : workspace.translateEverything,
              ),
              PreviewButton(
                label: LocaleKeys.editorExport.tr(),
                icon: HugeIcons.strokeRoundedDownload04,
                primary: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < PreviewWorkspace.locales.length; i++) ...[
                Expanded(
                  child: _LocaleCard(
                    locale: PreviewWorkspace.locales[i],
                    workspace: workspace,
                  ),
                ),
                if (i != PreviewWorkspace.locales.length - 1)
                  const SizedBox(width: 12),
              ],
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          _Toolbar(workspace: workspace),
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
                        (26, LocaleKeys.editorKeyLabel.tr().toUpperCase()),
                        (
                          22,
                          'EN · '
                              '${LocaleKeys.appSettingsMetaSource.tr().toUpperCase()}',
                        ),
                        for (final locale in PreviewWorkspace.locales)
                          (
                            22,
                            '${SupportedLanguages.flagOf(locale)}  '
                                '${locale.toUpperCase()}',
                          ),
                      ],
                    ),
                    Expanded(
                      child: rows.isEmpty
                          ? _EmptyResult(query: workspace.query)
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              // Never scrolls on its own: the rows are
                              // sized to fit, so a wheel event over the
                              // table still scrolls the page.
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rows.length,
                              itemBuilder: (context, index) => _EntryRow(
                                entry: rows[index],
                                workspace: workspace,
                              ),
                            ),
                    ),
                    _TableFooter(shown: rows.length, workspace: workspace),
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

class _LocaleCard extends StatelessWidget {
  const _LocaleCard({required this.locale, required this.workspace});

  final String locale;
  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final missing = workspace.missingIn(locale);
    final progress = workspace.progressIn(locale);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(color: tokens.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${SupportedLanguages.flagOf(locale)}  '
                '${locale.toUpperCase()}',
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.foreground,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          WorkspaceProgressBar(
            value: progress,
            isComplete: missing == 0,
            minHeight: 6,
          ),
          const SizedBox(height: 7),
          Text(
            missing == 0
                ? LocaleKeys.appsStatusComplete.tr()
                : LocaleKeys.commonMissingCount.plural(missing),
            style: TextStyle(
              fontSize: 11.5,
              color: missing == 0
                  ? LingoDeskColors.complete
                  : LingoDeskColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.workspace});

  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        WorkspaceMetaTile(
          label: LocaleKeys.dashboardStatKeys.tr(),
          value: workspace.entries.length.toString(),
          icon: HugeIcons.strokeRoundedKey01,
          width: 96,
          height: 48,
        ),
        const SizedBox(width: 8),
        WorkspaceMetaTile(
          label: LocaleKeys.dashboardMetricMissing.tr(),
          value: workspace.totalMissing.toString(),
          icon: HugeIcons.strokeRoundedAlertCircle,
          width: 106,
          height: 48,
        ),
        const SizedBox(width: 8),
        WorkspaceMetaTile(
          label: LocaleKeys.appsTableColLanguages.tr(),
          value: PreviewWorkspace.locales.length.toString(),
          icon: HugeIcons.strokeRoundedLanguageSquare,
          width: 120,
          height: 48,
        ),
        const SizedBox(width: 12),
        Expanded(child: _SearchField(workspace: workspace)),
        const SizedBox(width: 12),
        _MissingToggle(workspace: workspace),
        const SizedBox(width: 12),
        PreviewButton(
          label: LocaleKeys.editorAddKey.tr(),
          icon: HugeIcons.strokeRoundedAdd01,
          primary: true,
          height: 48,
        ),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.workspace});

  final PreviewWorkspace workspace;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final focused = _focus.hasFocus;

    return Container(
      height: 48,
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
            size: 17,
            color: focused ? tokens.accent : tokens.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              onChanged: widget.workspace.setQuery,
              cursorColor: tokens.accent,
              style: TextStyle(fontSize: 13.5, color: tokens.foreground),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: LocaleKeys.editorSearchHint.tr(),
                hintStyle: TextStyle(fontSize: 13.5, color: tokens.muted),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            _IconTap(
              icon: HugeIcons.strokeRoundedCancel01,
              onTap: () {
                _controller.clear();
                widget.workspace.setQuery('');
              },
            ),
        ],
      ),
    );
  }
}

class _MissingToggle extends StatelessWidget {
  const _MissingToggle({required this.workspace});

  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final on = workspace.missingOnly;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: workspace.toggleMissingOnly,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? tokens.brandFill : tokens.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: on ? tokens.brandFillBorder : tokens.border,
            ),
          ),
          child: Text(
            LocaleKeys.editorMissingOnly.tr(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: on ? tokens.onBrandFill : tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatefulWidget {
  const _EntryRow({required this.entry, required this.workspace});

  final PreviewEntry entry;
  final PreviewWorkspace workspace;

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered ? tokens.active : Colors.transparent,
          border: Border(bottom: BorderSide(color: tokens.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 26,
              child: Text(
                widget.entry.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.foreground,
                  fontSize: 12.5,
                ),
              ),
            ),
            Expanded(
              flex: 22,
              child: Text(
                widget.entry.source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: tokens.muted),
              ),
            ),
            for (final locale in PreviewWorkspace.locales)
              Expanded(
                flex: 22,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Cell(
                    entry: widget.entry,
                    locale: locale,
                    workspace: widget.workspace,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One editable translation. Empty cells carry the warning tint the real
/// editor uses, and lose it the moment you type into them.
class _Cell extends StatefulWidget {
  const _Cell({
    required this.entry,
    required this.locale,
    required this.workspace,
  });

  final PreviewEntry entry;
  final String locale;
  final PreviewWorkspace workspace;

  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
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
    final controller = widget.workspace.controllerFor(
      widget.entry.key,
      widget.locale,
    );
    final empty = controller.text.isEmpty;
    final focused = _focus.hasFocus;

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: empty && !focused
            ? LingoDeskColors.warning.withAlpha(tokens.isDark ? 38 : 22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
        border: Border.all(color: focused ? tokens.accent : Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        focusNode: _focus,
        onChanged: (value) =>
            widget.workspace.setValue(widget.entry, widget.locale, value),
        cursorColor: tokens.accent,
        style: TextStyle(fontSize: 13, color: tokens.foreground),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: LocaleKeys.dashboardMetricMissing.tr(),
          hintStyle: const TextStyle(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: LingoDeskColors.warning,
          ),
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LingoDeskIcon(
            HugeIcons.strokeRoundedSearch01,
            size: 26,
            color: tokens.muted,
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty
                ? LocaleKeys.landingPreviewNothingMissing.tr()
                : LocaleKeys.landingPreviewNoMatches.tr(
                    namedArgs: {'query': query},
                  ),
            style: TextStyle(fontSize: 14, color: tokens.muted),
          ),
        ],
      ),
    );
  }
}

class _TableFooter extends StatelessWidget {
  const _TableFooter({required this.shown, required this.workspace});

  final int shown;
  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.card,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          Text(
            '$shown of ${workspace.entries.length} keys · '
            '${workspace.totalMissing} missing',
            style: TextStyle(fontSize: 12.5, color: tokens.muted),
          ),
          const Spacer(),
          Text(
            '${LocaleKeys.commonRows.tr()}  25',
            style: TextStyle(fontSize: 12.5, color: tokens.muted),
          ),
          const SizedBox(width: 12),
          const _IconTap(icon: HugeIcons.strokeRoundedArrowLeft01),
          const SizedBox(width: 4),
          Text(
            '1 / 1',
            style: TextStyle(fontSize: 12.5, color: tokens.foreground),
          ),
          const SizedBox(width: 4),
          const _IconTap(icon: HugeIcons.strokeRoundedArrowRight01),
        ],
      ),
    );
  }
}

class _IconTap extends StatefulWidget {
  const _IconTap({required this.icon, this.onTap});

  final List<List<dynamic>> icon;
  final VoidCallback? onTap;

  @override
  State<_IconTap> createState() => _IconTapState();
}

class _IconTapState extends State<_IconTap> {
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
        child: SizedBox.square(
          dimension: 26,
          child: Center(
            child: LingoDeskIcon(
              widget.icon,
              size: 16,
              color: _hovered ? tokens.foreground : tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}
