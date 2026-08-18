import 'package:flutter/material.dart';

import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';

/// Space Mono ships in the bundle already; machine strings on the page
/// are set in it so JSON reads as JSON.
const String kMonoFamily = 'Space Mono';

/// A titled panel holding a scrap of JSON, drawn rather than screenshot
/// so it stays crisp and themes with the rest of the page.
class JsonPanel extends StatelessWidget {
  const JsonPanel({
    super.key,
    required this.filename,
    required this.lines,
    this.flagged = false,
  });

  final String filename;
  final List<JsonLine> lines;

  /// Marks the file as the one with a hole in it.
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.border)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.data_object,
                  size: 14,
                  color: flagged ? LingoDeskColors.warningLift : tokens.muted,
                ),
                const SizedBox(width: 8),
                Text(
                  filename,
                  style: TextStyle(
                    fontFamily: kMonoFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.foreground,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [for (final line in lines) _JsonLineView(line: line)],
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the rendered JSON: indentation, and whether it is a hole.
class JsonLine {
  const JsonLine(this.text, {this.indent = 0, this.missing = false});

  final String text;
  final int indent;

  /// Renders as an amber gap — the thing the product exists to remove.
  final bool missing;
}

class _JsonLineView extends StatelessWidget {
  const _JsonLineView({required this.line});

  final JsonLine line;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final colour = line.missing ? LingoDeskColors.warningLift : tokens.muted;

    return Padding(
      padding: EdgeInsets.only(left: line.indent * 14.0, bottom: 5),
      child: Text(
        line.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: kMonoFamily,
          fontSize: 12,
          height: 1.4,
          fontWeight: line.missing ? FontWeight.w700 : FontWeight.w400,
          color: colour,
        ),
      ),
    );
  }
}

/// The same strings as [JsonPanel], laid out the way LingoDesk shows
/// them: one row per key, one column per locale, holes visible at a
/// glance.
class GridPanel extends StatelessWidget {
  const GridPanel({super.key, required this.rows, required this.locales});

  final List<GridRow> rows;
  final List<String> locales;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: tokens.active,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(LingoDeskTheme.radius - 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: _HeaderCell(label: 'Key')),
                for (final locale in locales)
                  Expanded(flex: 2, child: _HeaderCell(label: locale)),
              ],
            ),
          ),
          for (final row in rows) _GridRowView(row: row, locales: locales),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: tokens.muted,
      ),
    );
  }
}

/// A key and its value in each locale; a null value is a missing string.
class GridRow {
  const GridRow(this.key, this.values);

  final String key;
  final List<String?> values;
}

class _GridRowView extends StatelessWidget {
  const _GridRowView({required this.row, required this.locales});

  final GridRow row;
  final List<String> locales;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kMonoFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: tokens.foreground,
              ),
            ),
          ),
          for (final value in row.values)
            Expanded(flex: 2, child: _ValueCell(value: value)),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final text = value;

    if (text == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: LingoDeskColors.warningDeep,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: LingoDeskColors.warningDeepBorder),
          ),
          child: const Text(
            'missing',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: LingoDeskColors.warningLift,
            ),
          ),
        ),
      );
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12.5, color: tokens.muted),
    );
  }
}
