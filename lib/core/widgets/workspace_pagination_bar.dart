import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/lingo_desk_motion.dart';
import '../theme/lingo_desk_theme.dart';
import '../theme/lingo_desk_tokens.dart';
import 'lingo_desk_dropdown.dart';
import 'lingo_desk_field.dart';
import 'lingo_desk_icon.dart';

/// The footer every paginated table in the workspace ends with: a count on
/// the left, page-size and page controls on the right.
///
/// [summary] is passed in because each table counts something different —
/// lines and keys in the translation grid, saved keys here.
class WorkspacePaginationBar extends StatelessWidget {
  const WorkspacePaginationBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.pageSize,
    required this.summary,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.pageSizes = const [10, 25, 50],
  });

  final int page;
  final int pageCount;
  final int pageSize;
  final List<int> pageSizes;

  /// Left-hand label, e.g. `1-10 of 24 keys`.
  final String summary;

  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final mutedStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      // The count anchors the left edge and the controls the right, with all
      // the slack between them.
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary,
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
    final enabled = onPressed != null;

    return Tooltip(
      message: tooltip,
      child: AnimatedOpacity(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        opacity: enabled ? 1 : 0.35,
        child: SizedBox.square(
          dimension: 30,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            onPressed: onPressed,
            icon: LingoDeskIcon(icon, size: 16, color: tokens.foreground),
          ),
        ),
      ),
    );
  }
}
