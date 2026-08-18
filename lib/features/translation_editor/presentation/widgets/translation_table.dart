import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
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
  static const _languageWidth = 230.0;

  // Budget for the trailing delete button plus the row's horizontal
  // padding, so rows never overflow at the table's minimum width.
  static const _actionWidth = 72.0;

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
        // Fixed columns leave a dead strip on the right of a wide window,
        // so share out any slack between the language columns and only
        // fall back to scrolling once they hit their minimum.
        final slack =
            constraints.maxWidth -
            TranslationTableWidget._keyWidth -
            TranslationTableWidget._actionWidth;
        final languageWidth = math.max(
          TranslationTableWidget._languageWidth,
          slack / languages.length,
        );
        final tableWidth =
            TranslationTableWidget._keyWidth +
            TranslationTableWidget._actionWidth +
            languageWidth * languages.length;

        return Container(
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
            border: Border.all(color: tokens.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        _TableHeaderRow(
                          languages: languages,
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
                                  ? _EmptyRows(
                                    state: widget.state,
                                    tokens: tokens,
                                  )
                                  : ListView.builder(
                                    itemCount: pageSlots.length,
                                    itemBuilder: (context, index) {
                                      return _buildSlot(
                                        context,
                                        pageSlots[index],
                                        languages,
                                        languageWidth,
                                        tokens,
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
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
    List<String> languages,
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
      languages: languages,
      languageWidth: languageWidth,
      sourceLanguage: widget.state.app.sourceLanguage,
      tokens: tokens,
      isFirstInGroup: row.isFirstInGroup,
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
    required this.languageWidth,
    required this.sourceLanguage,
    required this.tokens,
  });

  final List<String> languages;
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
          SizedBox(
            width: TranslationTableWidget._keyWidth - 16,
            child: Text('Key', style: headerStyle),
          ),
          for (final language in languages)
            SizedBox(
              width: languageWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  language == sourceLanguage
                      ? '${language.toUpperCase()} - source'
                      : language.toUpperCase(),
                  style: headerStyle,
                ),
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// The shared namespace lifted out of its rows, as a collapsible band.
class _GroupBand extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final indent = TranslationTableWidget.indentFor(group.depth - 1);
    final count = group.entries.length;

    return InkWell(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.isDark ? Colors.white.withAlpha(8) : tokens.active,
          border: Border(bottom: BorderSide(color: _hairline(tokens))),
        ),
        padding: EdgeInsets.fromLTRB(16 + indent, 9, 16, 9),
        child: Row(
          children: [
            LingoDeskIcon(
              isCollapsed
                  ? HugeIcons.strokeRoundedArrowRight01
                  : HugeIcons.strokeRoundedArrowDown01,
              size: 15,
              color: tokens.muted,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _Breadcrumb(segments: group.segments, tokens: tokens),
            ),
            const SizedBox(width: 10),
            Text(
              isContinuation ? '$count keys, continued' : '$count keys',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
    required this.languageWidth,
    required this.sourceLanguage,
    required this.tokens,
    required this.isFirstInGroup,
  });

  final TranslationEntry entry;
  final String leaf;
  final int depth;
  final List<String> languages;
  final double languageWidth;
  final String sourceLanguage;
  final LingoDeskTokens tokens;
  final bool isFirstInGroup;

  @override
  State<_TranslationRow> createState() => _TranslationRowState();
}

class _TranslationRowState extends State<_TranslationRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final indent = TranslationTableWidget.indentFor(widget.depth);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          // Siblings sit flush; only the seam between groups is drawn.
          border:
              widget.isFirstInGroup
                  ? null
                  : Border(top: BorderSide(color: _hairline(tokens))),
        ),
        padding: EdgeInsets.fromLTRB(16 + indent, 5, 16, 5),
        child: Row(
          children: [
            SizedBox(
              width: TranslationTableWidget._keyWidth - 16 - indent,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: widget.entry.key,
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
                  ),
                ),
              ),
            const Spacer(),
            // Destructive and permanent, so it stays quiet until the row is
            // under the pointer — but never fully hidden, or it would be
            // undiscoverable without a mouse.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _hovered ? 1 : 0.3,
              child: IconButton(
                tooltip: 'Delete key',
                onPressed: () => _confirmDelete(context),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                padding: EdgeInsets.zero,
                icon: LingoDeskIcon(
                  HugeIcons.strokeRoundedDelete02,
                  color: tokens.muted,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      child: Row(
        children: [
          Flexible(
            child: Text(
              total == 0
                  ? 'No keys'
                  : '$firstIndex-$lastIndex of $total lines - $rowCount keys',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mutedStyle,
            ),
          ),
          const Spacer(),
          Text('Rows', style: mutedStyle),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: pageSize,
              isDense: true,
              borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
              style: LingoDeskTheme.codeStyle.copyWith(
                color: tokens.foreground,
                fontSize: 12,
              ),
              items: [
                for (final size in pageSizes)
                  DropdownMenuItem(value: size, child: Text('$size')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onPageSizeChanged(value);
                }
              },
            ),
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
      icon: LingoDeskIcon(
        icon,
        size: 17,
        color: onPressed == null ? tokens.muted.withAlpha(90) : tokens.muted,
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
  });

  final String entryKey;
  final String language;
  final String value;
  final bool highlightMissing;

  @override
  Widget build(BuildContext context) {
    return TranslationCellField(
      key: ValueKey('$entryKey::$language'),
      value: value,
      highlightMissing: highlightMissing,
      onChanged:
          (newValue) => context.read<TranslationEditorBloc>().add(
            UpdateCellEvent(key: entryKey, language: language, value: newValue),
          ),
    );
  }
}
