import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_dropdown.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_menu.dart';
import '../../../../core/widgets/lingo_desk_toast.dart';
import '../../domain/entities/translation_entry.dart';
import '../bloc/translation_editor_bloc.dart';
import '../bloc/translation_editor_event.dart';
import '../bloc/translation_editor_state.dart';
import 'translation_cell_field.dart';

/// The translation grid, segmented by key namespace.
///
/// Flat dot-keys hide their own structure: `admins.categories.add.desc`
/// repeats its first three segments on every sibling row. Here the shared
/// prefix is lifted into a collapsible band and each row keeps only its
/// leaf, indented by how deep it sits. Long key sets are paginated so the
/// grid stays a fixed height instead of scrolling forever.
class TranslationTableWidget extends StatefulWidget {
  const TranslationTableWidget({super.key, required this.state});

  final TranslationEditorLoaded state;

  static const _keyWidth = 300.0;

  /// How far the key column gives way before the language columns start
  /// dropping into the collapsible section.
  static const _keyMinWidth = 190.0;

  /// A language column narrower than this stops being editable, so the
  /// table hides the column instead of shrinking past it.
  static const _languageMinWidth = 210.0;

  // Budget for the trailing delete button plus the row's horizontal
  // padding, so rows never overflow at the table's minimum width.
  static const _actionWidth = 72.0;

  /// Leading column holding the row's expander chevron.
  static const _expanderWidth = 28.0;

  /// Nesting inset per namespace level, capped so deep trees still leave
  /// the leaf readable.
  static const _indentStep = 14.0;
  static const _maxIndentLevels = 4;

  static double indentFor(int depth) =>
      math.min(depth, _maxIndentLevels) * _indentStep;

  @override
  State<TranslationTableWidget> createState() => _TranslationTableWidgetState();
}

class _TranslationTableWidgetState extends State<TranslationTableWidget> {
  static const _pageSizes = [25, 50, 100];

  final Set<String> _collapsed = <String>{};
  int _page = 0;
  int _pageSize = 25;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final languages = widget.state.app.allLanguages;
    final groups = _buildGroups(widget.state.filteredEntries);
    final slots = _buildSlots(groups);

    final pageCount = math.max(1, (slots.length / _pageSize).ceil());
    // Filters shrink the list under our feet; clamp rather than strand the
    // user on a page that no longer exists.
    final page = _page.clamp(0, pageCount - 1);
    final start = page * _pageSize;
    final end = math.min(start + _pageSize, slots.length);
    final pageSlots = slots.sublist(math.min(start, slots.length), end);

    // A page that opens mid-group would otherwise show orphaned leaves.
    final _Group? carriedGroup =
        pageSlots.isNotEmpty && pageSlots.first is _RowSlot
            ? (pageSlots.first as _RowSlot).group
            : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Everything fits the pane: the key column gives way first, then
        // the language columns share out what is left. Languages past
        // what fits move into each row's collapsible section rather than
        // off the right edge, so the table never scrolls sideways.
        final keyWidth = math.min(
          TranslationTableWidget._keyWidth,
          math.max(
            TranslationTableWidget._keyMinWidth,
            constraints.maxWidth * 0.3,
          ),
        );
        final slack = math.max(
          TranslationTableWidget._languageMinWidth,
          constraints.maxWidth -
              keyWidth -
              TranslationTableWidget._actionWidth -
              TranslationTableWidget._expanderWidth,
        );
        final visibleCount = (slack / TranslationTableWidget._languageMinWidth)
            .floor()
            .clamp(1, languages.length);
        final languageWidth = slack / visibleCount;
        final visibleLanguages = languages.sublist(0, visibleCount);
        // The source language leads [allLanguages], so the columns that
        // drop out are always targets — the reference stays on screen.
        final hiddenLanguages = languages.sublist(visibleCount);

        return Container(
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
            border: Border.all(color: tokens.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _TableHeaderRow(
                languages: visibleLanguages,
                hiddenCount: hiddenLanguages.length,
                keyWidth: keyWidth,
                languageWidth: languageWidth,
                sourceLanguage: widget.state.app.sourceLanguage,
                tokens: tokens,
              ),
              if (carriedGroup != null)
                _GroupBand(
                  group: carriedGroup,
                  tokens: tokens,
                  isCollapsed: false,
                  isContinuation: true,
                  onToggle: () => _toggle(carriedGroup.prefix),
                ),
              Expanded(
                child:
                    slots.isEmpty
                        ? _EmptyRows(state: widget.state, tokens: tokens)
                        : ListView.builder(
                          itemCount: pageSlots.length,
                          itemBuilder: (context, index) {
                            return _buildSlot(
                              context,
                              pageSlots[index],
                              visibleLanguages,
                              hiddenLanguages,
                              keyWidth,
                              languageWidth,
                              tokens,
                            );
                          },
                        ),
              ),
              _PaginationBar(
                tokens: tokens,
                page: page,
                pageCount: pageCount,
                pageSize: _pageSize,
                pageSizes: _pageSizes,
                firstIndex: slots.isEmpty ? 0 : start + 1,
                lastIndex: end,
                total: slots.length,
                rowCount: groups.fold(0, (sum, g) => sum + g.entries.length),
                onPageChanged: (value) => setState(() => _page = value),
                onPageSizeChanged:
                    (value) => setState(() {
                      _pageSize = value;
                      _page = 0;
                    }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlot(
    BuildContext context,
    _Slot slot,
    List<String> visibleLanguages,
    List<String> hiddenLanguages,
    double keyWidth,
    double languageWidth,
    LingoDeskTokens tokens,
  ) {
    if (slot is _GroupSlot) {
      return _GroupBand(
        group: slot.group,
        tokens: tokens,
        isCollapsed: _collapsed.contains(slot.group.prefix),
        isContinuation: false,
        onToggle: () => _toggle(slot.group.prefix),
      );
    }

    final row = slot as _RowSlot;
    return _TranslationRow(
      key: ValueKey(row.entry.key),
      entry: row.entry,
      leaf: row.leaf,
      depth: row.group.depth,
      languages: visibleLanguages,
      hiddenLanguages: hiddenLanguages,
      keyWidth: keyWidth,
      languageWidth: languageWidth,
      sourceLanguage: widget.state.app.sourceLanguage,
      tokens: tokens,
      isFirstInGroup: row.isFirstInGroup,
      aiJob: widget.state.aiJob,
    );
  }

  void _toggle(String prefix) {
    setState(() {
      if (!_collapsed.remove(prefix)) {
        _collapsed.add(prefix);
      }
    });
  }

  /// Buckets entries by everything before the final dot segment.
  ///
  /// Entries arrive sorted by key, so siblings are already contiguous and
  /// one pass is enough.
  List<_Group> _buildGroups(List<TranslationEntry> entries) {
    final groups = <_Group>[];

    for (final entry in entries) {
      final parts = entry.key.split('.');
      final prefix =
          parts.length > 1 ? parts.sublist(0, parts.length - 1).join('.') : '';

      if (groups.isEmpty || groups.last.prefix != prefix) {
        groups.add(
          _Group(
            prefix: prefix,
            segments: prefix.isEmpty ? const [] : prefix.split('.'),
            entries: [entry],
          ),
        );
      } else {
        groups.last.entries.add(entry);
      }
    }

    return groups;
  }

  /// Flattens groups into the exact line sequence the table renders, so
  /// pagination counts what the eye counts.
  List<_Slot> _buildSlots(List<_Group> groups) {
    final slots = <_Slot>[];

    for (final group in groups) {
      // Root-level keys carry no shared prefix worth a band.
      if (group.prefix.isNotEmpty) {
        slots.add(_GroupSlot(group));
        if (_collapsed.contains(group.prefix)) {
          continue;
        }
      }
      for (var i = 0; i < group.entries.length; i++) {
        final entry = group.entries[i];
        slots.add(
          _RowSlot(
            group: group,
            entry: entry,
            leaf: entry.key.split('.').last,
            isFirstInGroup: i == 0,
          ),
        );
      }
    }

    return slots;
  }
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class _Group {
  _Group({required this.prefix, required this.segments, required this.entries});

  /// Shared namespace, e.g. `admins.categories.add`. Empty at root.
  final String prefix;
  final List<String> segments;
  final List<TranslationEntry> entries;

  int get depth => segments.length;
}

sealed class _Slot {}

class _GroupSlot extends _Slot {
  _GroupSlot(this.group);

  final _Group group;
}

class _RowSlot extends _Slot {
  _RowSlot({
    required this.group,
    required this.entry,
    required this.leaf,
    required this.isFirstInGroup,
  });

  final _Group group;
  final TranslationEntry entry;
  final String leaf;
  final bool isFirstInGroup;
}

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

/// Hairlines at full strength turn the grid into graph paper; every rule
/// in the table is drawn at this weight instead.
Color _hairline(LingoDeskTokens tokens) =>
    tokens.isDark ? Colors.white10 : tokens.border.withAlpha(130);

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({
    required this.languages,
    required this.hiddenCount,
    required this.keyWidth,
    required this.languageWidth,
    required this.sourceLanguage,
    required this.tokens,
  });

  final List<String> languages;

  /// Languages that did not fit, and so live in the rows' collapsible
  /// sections instead of in a column here.
  final int hiddenCount;

  final double keyWidth;
  final double languageWidth;
  final String sourceLanguage;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: tokens.muted,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.active,
        border: Border(bottom: BorderSide(color: _hairline(tokens))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          const SizedBox(width: TranslationTableWidget._expanderWidth),
          SizedBox(
            width: keyWidth - 16 - TranslationTableWidget._expanderWidth,
            child: Text('Key', style: headerStyle),
          ),
          for (final language in languages)
            SizedBox(
              width: languageWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _LanguageLabel(
                  language: language,
                  label:
                      language == sourceLanguage
                          ? '${language.toUpperCase()} - source'
                          : language.toUpperCase(),
                  style: headerStyle,
                ),
              ),
            ),
          const Spacer(),
          // Says where the missing columns went, so a narrow window reads
          // as folded rather than truncated. It has to live inside the
          // gutter the row menus use, so the count carries it and the
          // sentence goes in the tooltip.
          if (hiddenCount > 0)
            Tooltip(
              message:
                  '$hiddenCount more '
                  '${hiddenCount == 1 ? 'language' : 'languages'}, '
                  'inside each row',
              child: Text('+$hiddenCount', style: headerStyle),
            ),
        ],
      ),
    );
  }
}

/// The shared namespace lifted out of its rows, as a collapsible band.
class _GroupBand extends StatefulWidget {
  const _GroupBand({
    required this.group,
    required this.tokens,
    required this.isCollapsed,
    required this.isContinuation,
    required this.onToggle,
  });

  final _Group group;
  final LingoDeskTokens tokens;
  final bool isCollapsed;

  /// True when redrawn at the top of a page that opens mid-group.
  final bool isContinuation;

  final VoidCallback onToggle;

  @override
  State<_GroupBand> createState() => _GroupBandState();
}

class _GroupBandState extends State<_GroupBand> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final tokens = widget.tokens;
    final isCollapsed = widget.isCollapsed;
    final indent = TranslationTableWidget.indentFor(group.depth - 1);
    final count = group.entries.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onToggle,
        hoverColor: Colors.transparent,
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          decoration: BoxDecoration(
            color: _bandColor(tokens),
            border: Border(bottom: BorderSide(color: _hairline(tokens))),
          ),
          padding: EdgeInsets.fromLTRB(16 + indent, 9, 16, 9),
          child: Row(
            children: [
              // One arrow that turns, rather than two that swap: the
              // rotation is what says "this opens and closes".
              AnimatedRotation(
                turns: isCollapsed ? 0 : 0.25,
                duration: LingoDeskMotion.standard,
                curve: LingoDeskMotion.curve,
                child: LingoDeskIcon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: 15,
                  color: _hovered ? tokens.foreground : tokens.muted,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _Breadcrumb(segments: group.segments, tokens: tokens),
              ),
              const SizedBox(width: 10),
              Text(
                widget.isContinuation
                    ? '$count keys, continued'
                    : '$count keys',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _bandColor(LingoDeskTokens tokens) {
    if (tokens.isDark) {
      return Colors.white.withAlpha(_hovered ? 16 : 8);
    }
    return _hovered ? LingoDeskColors.activeLight : tokens.active;
  }
}

/// `admins › categories › add`, with the final segment carrying the weight.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.segments, required this.tokens});

  final List<String> segments;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    final base = LingoDeskTheme.codeStyle.copyWith(fontSize: 12);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i != 0)
              TextSpan(
                text: '  ${String.fromCharCode(0x203A)}  ',
                style: base.copyWith(color: tokens.muted),
              ),
            TextSpan(
              text: segments[i],
              style: base.copyWith(
                color:
                    i == segments.length - 1 ? tokens.foreground : tokens.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TranslationRow extends StatefulWidget {
  const _TranslationRow({
    super.key,
    required this.entry,
    required this.leaf,
    required this.depth,
    required this.languages,
    required this.hiddenLanguages,
    required this.keyWidth,
    required this.languageWidth,
    required this.sourceLanguage,
    required this.tokens,
    required this.isFirstInGroup,
    this.aiJob,
  });

  final TranslationEntry entry;
  final String leaf;
  final int depth;

  /// Languages with a column of their own on this row.
  final List<String> languages;

  /// Languages that did not fit a column; they live in the section that
  /// opens under the row.
  final List<String> hiddenLanguages;

  final double keyWidth;
  final double languageWidth;
  final String sourceLanguage;
  final LingoDeskTokens tokens;
  final bool isFirstInGroup;

  /// The running AI pass, so cells this row owns can show a spinner.
  final AiJob? aiJob;

  @override
  State<_TranslationRow> createState() => _TranslationRowState();
}

class _TranslationRowState extends State<_TranslationRow> {
  bool _hovered = false;
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final indent = TranslationTableWidget.indentFor(widget.depth);
    final hidden = widget.hiddenLanguages;
    final canExpand = hidden.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        decoration: BoxDecoration(
          // A whisper of fill, just enough to tie a key to its cells
          // across a wide grid without turning the table into zebra
          // stripes.
          color:
              _hovered || _expanded
                  ? (tokens.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : tokens.active.withValues(alpha: 0.5))
                  : null,
          // Siblings sit flush; only the seam between groups is drawn.
          border:
              widget.isFirstInGroup
                  ? null
                  : Border(top: BorderSide(color: _hairline(tokens))),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16 + indent, 5, 16, 5),
              child: Row(
                children: [
                  SizedBox(
                    width: TranslationTableWidget._expanderWidth,
                    child:
                        canExpand
                            ? _RowExpander(
                              expanded: _expanded,
                              hovered: _hovered,
                              hiddenCount: hidden.length,
                              tokens: tokens,
                              onTap: _toggle,
                            )
                            : null,
                  ),
                  SizedBox(
                    width:
                        widget.keyWidth -
                        16 -
                        indent -
                        TranslationTableWidget._expanderWidth,
                    // The key is the row's own handle, so it opens the
                    // section too — a chevron-sized target is a lot to
                    // ask for something the whole row is about. The
                    // language cells stay untouched: a click there is
                    // aimed at the field.
                    child: InkWell(
                      onTap: canExpand ? _toggle : null,
                      hoverColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Tooltip(
                            message:
                                canExpand
                                    ? '${widget.entry.key}\nClick to '
                                        '${_expanded ? 'hide' : 'show'} the '
                                        'other languages'
                                    : widget.entry.key,
                            waitDuration: const Duration(milliseconds: 500),
                            child: Text(
                              widget.leaf,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: LingoDeskTheme.codeStyle.copyWith(
                                color: tokens.foreground,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final language in widget.languages)
                    SizedBox(
                      width: widget.languageWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: TranslationCellFieldForRow(
                          entryKey: widget.entry.key,
                          language: language,
                          value: widget.entry.valueFor(language),
                          highlightMissing: language != widget.sourceLanguage,
                          canTranslate: _canTranslate(language),
                          isTranslating:
                              widget.aiJob?.isPending(
                                widget.entry.key,
                                language,
                              ) ??
                              false,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Destructive and permanent, so it stays quiet until the
                  // row is under the pointer — but never fully hidden, or
                  // it would be undiscoverable without a mouse.
                  AnimatedOpacity(
                    duration: LingoDeskMotion.fast,
                    curve: LingoDeskMotion.curve,
                    opacity: _hovered ? 1 : 0.3,
                    child: LingoDeskMenuButton<String>(
                      tooltip: 'Key actions',
                      menuWidth: 190,
                      items: [
                        LingoDeskMenuItem(
                          value: 'ai',
                          label: 'AI translate row',
                          icon: HugeIcons.strokeRoundedSparkles,
                          enabled: _missingLanguages.isNotEmpty,
                        ),
                        const LingoDeskMenuItem(
                          value: 'copy',
                          label: 'Copy key',
                          icon: HugeIcons.strokeRoundedCopy01,
                        ),
                        const LingoDeskMenuItem.divider(),
                        const LingoDeskMenuItem(
                          value: 'delete',
                          label: 'Delete key',
                          icon: HugeIcons.strokeRoundedDelete02,
                          destructive: true,
                        ),
                      ],
                      onSelected: (action) {
                        switch (action) {
                          case 'ai':
                            _translateRow(context);
                          case 'copy':
                            _copyKey(context);
                          case 'delete':
                            _confirmDelete(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: LingoDeskMotion.standard,
              curve: LingoDeskMotion.curve,
              alignment: Alignment.topCenter,
              child:
                  _expanded && canExpand
                      ? _HiddenLanguages(
                        entry: widget.entry,
                        languages: hidden,
                        indent: indent,
                        cellWidth: widget.languageWidth,
                        tokens: tokens,
                        aiJob: widget.aiJob,
                        canTranslate: _canTranslate,
                      )
                      : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  /// A cell can be AI-filled when it is a target column, still empty, and
  /// the source column actually has text to translate from.
  bool _canTranslate(String language) {
    return language != widget.sourceLanguage &&
        widget.entry.isMissingFor(language) &&
        widget.entry.valueFor(widget.sourceLanguage).trim().isNotEmpty;
  }

  /// Every target language this row is still missing.
  List<String> get _missingLanguages => [
    for (final language in [...widget.languages, ...widget.hiddenLanguages])
      if (_canTranslate(language)) language,
  ];

  void _translateRow(BuildContext context) {
    context.read<TranslationEditorBloc>().add(
      AiTranslateEvent(_missingLanguages, keys: {widget.entry.key}),
    );
  }

  void _copyKey(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.entry.key));
    context.showInfoToast('Copied "${widget.entry.key}" to the clipboard.');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<TranslationEditorBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete key?'),
            content: Text(
              'This removes "${widget.entry.key}" from every language. '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: LingoDeskColors.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed ?? false) {
      bloc.add(DeleteKeyEvent(widget.entry.key));
    }
  }
}

/// A language column's label: its flag, then its code. The flag is what
/// the eye finds first once a row carries more locales than columns.
class _LanguageLabel extends StatelessWidget {
  const _LanguageLabel({
    required this.language,
    required this.label,
    required this.style,
  });

  final String language;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          SupportedLanguages.flagOf(language),
          style: TextStyle(fontSize: (style?.fontSize ?? 12) + 1),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// The chevron at the start of a row whose languages did not all fit.
/// One arrow that turns, matching the namespace bands above it.
class _RowExpander extends StatelessWidget {
  const _RowExpander({
    required this.expanded,
    required this.hovered,
    required this.hiddenCount,
    required this.tokens,
    required this.onTap,
  });

  final bool expanded;
  final bool hovered;
  final int hiddenCount;
  final LingoDeskTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message:
            expanded
                ? 'Hide the other languages'
                : '$hiddenCount more '
                    '${hiddenCount == 1 ? 'language' : 'languages'}',
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: AnimatedRotation(
              turns: expanded ? 0.25 : 0,
              duration: LingoDeskMotion.standard,
              curve: LingoDeskMotion.curve,
              child: LingoDeskIcon(
                HugeIcons.strokeRoundedArrowRight01,
                size: 15,
                color: expanded || hovered ? tokens.foreground : tokens.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The languages with no column of their own, opened under their row and
/// fully editable — folding a column must not put a locale out of reach.
class _HiddenLanguages extends StatelessWidget {
  const _HiddenLanguages({
    required this.entry,
    required this.languages,
    required this.indent,
    required this.cellWidth,
    required this.tokens,
    required this.canTranslate,
    this.aiJob,
  });

  final TranslationEntry entry;
  final List<String> languages;
  final double indent;
  final double cellWidth;
  final LingoDeskTokens tokens;

  /// Same eligibility test the visible columns use, passed in so folding a
  /// column never changes what the cell can do.
  final bool Function(String language) canTranslate;

  final AiJob? aiJob;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: tokens.muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16 + indent + TranslationTableWidget._expanderWidth,
        2,
        16,
        12,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final language in languages)
            SizedBox(
              width: math.max(180, cellWidth - 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LanguageLabel(
                    language: language,
                    label: language.toUpperCase(),
                    style: labelStyle,
                  ),
                  const SizedBox(height: 4),
                  TranslationCellFieldForRow(
                    entryKey: entry.key,
                    language: language,
                    value: entry.valueFor(language),
                    highlightMissing: true,
                    canTranslate: canTranslate(language),
                    isTranslating:
                        aiJob?.isPending(entry.key, language) ?? false,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.tokens,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.pageSizes,
    required this.firstIndex,
    required this.lastIndex,
    required this.total,
    required this.rowCount,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final LingoDeskTokens tokens;
  final int page;
  final int pageCount;
  final int pageSize;
  final List<int> pageSizes;
  final int firstIndex;
  final int lastIndex;

  /// Total rendered lines (bands + rows) — what pagination slices.
  final int total;

  /// Translation keys behind those lines.
  final int rowCount;

  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        border: Border(top: BorderSide(color: _hairline(tokens))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      // The count anchors the left edge and the controls the right, with
      // all the slack between them: a Flexible label next to a Spacer
      // splits that slack in two and leaves the controls stranded
      // mid-bar.
      child: Row(
        children: [
          Expanded(
            child: Text(
              total == 0
                  ? 'No keys'
                  : '$firstIndex-$lastIndex of $total lines - $rowCount keys',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mutedStyle,
            ),
          ),
          const SizedBox(width: 16),
          Text('Rows', style: mutedStyle),
          const SizedBox(width: 8),
          LingoDeskDropdown<int>(
            items: [
              for (final size in pageSizes)
                LingoDeskDropdownItem(value: size, label: '$size'),
            ],
            value: pageSize,
            size: LingoDeskFieldSize.compact,
            expand: false,
            monospace: true,
            menuWidth: 96,
            onChanged: onPageSizeChanged,
          ),
          const SizedBox(width: 16),
          _PageButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            tooltip: 'Previous page',
            tokens: tokens,
            onPressed: page > 0 ? () => onPageChanged(page - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${page + 1} / $pageCount',
              style: LingoDeskTheme.codeStyle.copyWith(
                color: tokens.foreground,
                fontSize: 12,
              ),
            ),
          ),
          _PageButton(
            icon: HugeIcons.strokeRoundedArrowRight01,
            tooltip: 'Next page',
            tokens: tokens,
            onPressed:
                page < pageCount - 1 ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.tokens,
    required this.onPressed,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final LingoDeskTokens tokens;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      icon: AnimatedTint(
        // Reaching the first or last page dims the arrow rather than
        // greying it out in one frame.
        color: onPressed == null ? tokens.muted.withAlpha(90) : tokens.muted,
        duration: LingoDeskMotion.standard,
        builder: (context, tint) => LingoDeskIcon(icon, size: 17, color: tint),
      ),
    );
  }
}

class _EmptyRows extends StatelessWidget {
  const _EmptyRows({required this.state, required this.tokens});

  final TranslationEditorLoaded state;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    final hasEntries = state.entries.isNotEmpty;

    return Center(
      child: FadeSlideIn(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LingoDeskIcon(
                hasEntries
                    ? HugeIcons.strokeRoundedSearch01
                    : HugeIcons.strokeRoundedKey01,
                color: tokens.muted,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                hasEntries
                    ? 'No keys match the current filters.'
                    : 'No keys yet. Upload JSON files or add your first key.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wires a [TranslationCellField] to the bloc for one cell.
class TranslationCellFieldForRow extends StatelessWidget {
  const TranslationCellFieldForRow({
    super.key,
    required this.entryKey,
    required this.language,
    required this.value,
    required this.highlightMissing,
    this.canTranslate = false,
    this.isTranslating = false,
  });

  final String entryKey;
  final String language;
  final String value;
  final bool highlightMissing;

  /// Whether an AI pass could fill this cell: a target column, still empty,
  /// with source text to translate from.
  final bool canTranslate;

  final bool isTranslating;

  @override
  Widget build(BuildContext context) {
    return TranslationCellField(
      key: ValueKey('$entryKey::$language'),
      value: value,
      highlightMissing: highlightMissing,
      isTranslating: isTranslating,
      onAiTranslate:
          canTranslate
              ? () => context.read<TranslationEditorBloc>().add(
                AiTranslateCellEvent(key: entryKey, language: language),
              )
              : null,
      onChanged:
          (newValue) => context.read<TranslationEditorBloc>().add(
            UpdateCellEvent(key: entryKey, language: language, value: newValue),
          ),
    );
  }
}
