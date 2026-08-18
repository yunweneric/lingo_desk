import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/preferences/ai_settings_controller.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/lingo_desk_menu.dart';
import '../../../../core/widgets/workspace_pagination_bar.dart';
import '../../domain/entities/ai_key.dart';
import '../../domain/entities/ai_provider.dart';
import 'ai_provider_logo.dart';

/// What a row's menu asked for.
enum AiKeyAction { use, test, edit, delete }

/// Every saved key, one row each.
///
/// A table rather than a card per key: keys are records you scan and manage,
/// and once there is more than one per provider the useful questions become
/// "which of these is live" and "which one is this" — both of which a row of
/// aligned columns answers faster than a stack of forms.
class AiKeysTable extends StatefulWidget {
  const AiKeysTable({
    super.key,
    required this.settings,
    required this.onAction,
    this.testingKeyId,
  });

  final AiSettingsController settings;
  final void Function(AiKeyAction action, AiKey key) onAction;

  /// The key whose connection is being checked right now.
  final String? testingKeyId;

  @override
  State<AiKeysTable> createState() => _AiKeysTableState();
}

class _AiKeysTableState extends State<AiKeysTable> {
  int _page = 0;
  int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final keys = widget.settings.keys;

    final pageCount = math.max(1, (keys.length / _pageSize).ceil());
    // Deleting rows shrinks the list under our feet; clamp rather than
    // strand the user on a page that no longer exists.
    final page = _page.clamp(0, pageCount - 1);
    final start = page * _pageSize;
    final end = math.min(start + _pageSize, keys.length);
    final rows = keys.sublist(math.min(start, keys.length), end);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
        border: Border.all(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderRow(tokens: tokens),
          if (rows.isEmpty)
            _EmptyRow(tokens: tokens)
          else
            for (var i = 0; i < rows.length; i++)
              _KeyRow(
                entry: rows[i],
                isActive: rows[i].id == widget.settings.activeKeyId,
                isTesting: rows[i].id == widget.testingKeyId,
                isFirst: i == 0,
                tokens: tokens,
                onAction: (action) => widget.onAction(action, rows[i]),
              ),
          WorkspacePaginationBar(
            page: page,
            pageCount: pageCount,
            pageSize: _pageSize,
            summary:
                keys.isEmpty
                    ? 'No keys yet'
                    : '${start + 1}-$end of ${keys.length} '
                        'key${keys.length == 1 ? '' : 's'}',
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
  }
}

/// Column widths, shared by the header and every row so they stay aligned.
class _Columns {
  const _Columns._();

  static const provider = 190.0;
  static const model = 210.0;
  static const added = 120.0;
  static const actions = 96.0;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.tokens});

  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: tokens.muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.active,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _Columns.provider,
            child: Text('PROVIDER', style: style),
          ),
          Expanded(child: Text('API KEY', style: style)),
          SizedBox(width: _Columns.model, child: Text('MODEL', style: style)),
          SizedBox(width: _Columns.added, child: Text('ADDED', style: style)),
          SizedBox(
            width: _Columns.actions,
            child: Text('', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatefulWidget {
  const _KeyRow({
    required this.entry,
    required this.isActive,
    required this.isTesting,
    required this.isFirst,
    required this.tokens,
    required this.onAction,
  });

  final AiKey entry;
  final bool isActive;
  final bool isTesting;
  final bool isFirst;
  final LingoDeskTokens tokens;
  final ValueChanged<AiKeyAction> onAction;

  @override
  State<_KeyRow> createState() => _KeyRowState();
}

class _KeyRowState extends State<_KeyRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final entry = widget.entry;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        decoration: BoxDecoration(
          color:
              _hovered
                  ? (tokens.isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : tokens.active.withValues(alpha: 0.5))
                  : null,
          border:
              widget.isFirst
                  ? null
                  : Border(top: BorderSide(color: tokens.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: _Columns.provider,
              child: Row(
                children: [
                  AiProviderLogo(provider: entry.provider, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: tokens.foreground,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          entry.provider.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: tokens.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.maskedKey,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LingoDeskTheme.codeStyle.copyWith(
                          color: tokens.foreground,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (widget.isActive) ...[
                      const SizedBox(width: 10),
                      const _ActiveBadge(),
                    ],
                    if (widget.isTesting) ...[
                      const SizedBox(width: 10),
                      const SizedBox.square(
                        dimension: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LingoDeskColors.brandTeal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(
              width: _Columns.model,
              child: Text(
                entry.model,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LingoDeskTheme.codeStyle.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(
              width: _Columns.added,
              child: Text(
                DateFormatter.relative(entry.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(
              width: _Columns.actions,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  duration: LingoDeskMotion.fast,
                  curve: LingoDeskMotion.curve,
                  // Never fully hidden, or the row's actions would be
                  // undiscoverable without a mouse.
                  opacity: _hovered ? 1 : 0.4,
                  child: LingoDeskMenuButton<AiKeyAction>(
                    tooltip: 'Key actions',
                    menuWidth: 210,
                    items: [
                      LingoDeskMenuItem(
                        value: AiKeyAction.use,
                        label: 'Use for translations',
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        enabled: !widget.isActive && entry.isUsable,
                      ),
                      LingoDeskMenuItem(
                        value: AiKeyAction.test,
                        label: 'Test connection',
                        icon: HugeIcons.strokeRoundedPlugSocket,
                        enabled: !widget.isTesting,
                      ),
                      const LingoDeskMenuItem(
                        value: AiKeyAction.edit,
                        label: 'Edit',
                        icon: HugeIcons.strokeRoundedEdit02,
                      ),
                      const LingoDeskMenuItem.divider(),
                      const LingoDeskMenuItem(
                        value: AiKeyAction.delete,
                        label: 'Delete',
                        icon: HugeIcons.strokeRoundedDelete02,
                        destructive: true,
                      ),
                    ],
                    onSelected: widget.onAction,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LingoDeskColors.brandTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: LingoDeskColors.brandTeal.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'Active',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LingoDeskColors.brandTeal,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.tokens});

  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Center(
        child: Text(
          'No API keys yet. Add one to translate from the editor.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
        ),
      ),
    );
  }
}
