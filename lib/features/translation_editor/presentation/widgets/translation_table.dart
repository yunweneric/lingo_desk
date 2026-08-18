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

/// The flattened translation grid: one row per key, one editable
/// column per language.
class TranslationTableWidget extends StatelessWidget {
  const TranslationTableWidget({super.key, required this.state});

  final TranslationEditorLoaded state;

  static const _keyWidth = 260.0;
  static const _languageWidth = 230.0;

  // Budget for the trailing delete button plus the row's horizontal
  // padding, so rows never overflow at the table's minimum width.
  static const _actionWidth = 80.0;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final languages = state.app.allLanguages;
    final rows = state.filteredEntries;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth =
            _keyWidth + _actionWidth + _languageWidth * languages.length;
        final tableWidth = math.max(minWidth, constraints.maxWidth);

        return Container(
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _TableHeaderRow(
                    languages: languages,
                    sourceLanguage: state.app.sourceLanguage,
                    tokens: tokens,
                  ),
                  Divider(height: 1, color: tokens.border),
                  Expanded(
                    child:
                        rows.isEmpty
                            ? _EmptyRows(state: state, tokens: tokens)
                            : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder:
                                  (_, _) =>
                                      Divider(height: 1, color: tokens.border),
                              itemBuilder: (context, index) {
                                final entry = rows[index];
                                return _TranslationRow(
                                  key: ValueKey(entry.key),
                                  entry: entry,
                                  languages: languages,
                                  sourceLanguage: state.app.sourceLanguage,
                                  tokens: tokens,
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({
    required this.languages,
    required this.sourceLanguage,
    required this.tokens,
  });

  final List<String> languages;
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
      color: tokens.active,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: TranslationTableWidget._keyWidth - 16,
            child: Text('Key', style: headerStyle),
          ),
          for (final language in languages)
            SizedBox(
              width: TranslationTableWidget._languageWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
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

class _TranslationRow extends StatelessWidget {
  const _TranslationRow({
    super.key,
    required this.entry,
    required this.languages,
    required this.sourceLanguage,
    required this.tokens,
  });

  final TranslationEntry entry;
  final List<String> languages;
  final String sourceLanguage;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: TranslationTableWidget._keyWidth - 16,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                entry.key,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.foreground,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          for (final language in languages)
            SizedBox(
              width: TranslationTableWidget._languageWidth,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TranslationCellFieldForRow(
                  entryKey: entry.key,
                  language: language,
                  value: entry.valueFor(language),
                  highlightMissing: language != sourceLanguage,
                ),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Delete key',
            onPressed: () => _confirmDelete(context),
            icon: LingoDeskIcon(
              HugeIcons.strokeRoundedDelete02,
              color: tokens.muted,
              size: 18,
            ),
          ),
        ],
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
              'This removes "${entry.key}" from every language. '
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
      bloc.add(DeleteKeyEvent(entry.key));
    }
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
