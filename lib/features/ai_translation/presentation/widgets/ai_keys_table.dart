import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/preferences/ai_settings_controller.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/touch.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/lingo_desk_menu.dart';
import '../../../../core/widgets/workspace_pagination_bar.dart';
import '../../domain/entities/ai_key.dart';
import '../../domain/entities/ai_provider.dart';
import 'ai_provider_logo.dart';
import '../../../../core/localization/export.dart';

/// What a row's menu asked for.
enum AiKeyAction { use, test, edit, delete }

/// Every saved key, one row each.
///
/// A table rather than a card per key: keys are records you scan and manage,
/// and once there is more than one per provider the useful questions become
/// "which of these is live" and "which one is this" — both of which a row of
/// aligned columns answers faster than a stack of forms.
///
/// That argument only holds while the columns have room to be columns.
/// Below [WindowSizeClass.expanded] the same four facts stack into a card
/// per key, because five columns crushed into a phone's width answer
/// nothing at all.
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

    return ResponsiveBuilder(
      builder: (context, size, _) {
        final asCards = size.isBelow(WindowSizeClass.expanded);

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
              if (!asCards) _HeaderRow(tokens: tokens),
              if (rows.isEmpty)
                _EmptyRow(tokens: tokens)
              else
                for (var i = 0; i < rows.length; i++)
                  _KeyEntry(
                    entry: rows[i],
                    isActive: rows[i].id == widget.settings.activeKeyId,
                    isTesting: rows[i].id == widget.testingKeyId,
                    isFirst: i == 0,
                    asCard: asCards,
                    tokens: tokens,
                    onAction: (action) => widget.onAction(action, rows[i]),
                  ),
              WorkspacePaginationBar(
                page: page,
                pageCount: pageCount,
                pageSize: _pageSize,
                summary: keys.isEmpty
                    ? LocaleKeys.aiTableNoKeys.tr()
                    : LocaleKeys.aiTableRange.tr(
                        namedArgs: {
                          'start': '${start + 1}',
                          'end': '$end',
                          'total': LocaleKeys.aiKeyCount.plural(keys.length),
                        },
                      ),
                onPageChanged: (value) => setState(() => _page = value),
                onPageSizeChanged: (value) => setState(() {
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
}

/// Column weights, shared by the header and every row so they stay
/// aligned.
///
/// Weights rather than fixed widths: the four columns used to add up to
/// 616px of hard [SizedBox], which simply overflowed anything narrower
/// than a laptop. Sharing out the row proportionally lets the table hold
/// its shape all the way down to where it hands over to cards.
class _Columns {
  const _Columns._();

  static const provider = 5;
  static const apiKey = 5;
  static const model = 5;
  static const added = 3;

  /// The trailing menu needs a real width; it is a button, not text.
  static const actionsWidth = 96.0;
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

    Widget cell(String label, int flex) => Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.active,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Row(
        children: [
          cell(LocaleKeys.aiColProvider.tr().toUpperCase(), _Columns.provider),
          cell(LocaleKeys.aiColApiKey.tr().toUpperCase(), _Columns.apiKey),
          cell(LocaleKeys.aiColModel.tr().toUpperCase(), _Columns.model),
          cell(LocaleKeys.aiColAdded.tr().toUpperCase(), _Columns.added),
          const SizedBox(width: _Columns.actionsWidth),
        ],
      ),
    );
  }
}

/// One saved key — as a table row where the columns fit, as a card where
/// they do not.
class _KeyEntry extends StatefulWidget {
  const _KeyEntry({
    required this.entry,
    required this.isActive,
    required this.isTesting,
    required this.isFirst,
    required this.asCard,
    required this.tokens,
    required this.onAction,
  });

  final AiKey entry;
  final bool isActive;
  final bool isTesting;
  final bool isFirst;
  final bool asCard;
  final LingoDeskTokens tokens;
  final ValueChanged<AiKeyAction> onAction;

  @override
  State<_KeyEntry> createState() => _KeyEntryState();
}

class _KeyEntryState extends State<_KeyEntry> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: LingoDeskMotion.fast,
        curve: LingoDeskMotion.curve,
        decoration: BoxDecoration(
          color: _hovered
              ? (tokens.isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : tokens.active.withValues(alpha: 0.5))
              : null,
          border: widget.isFirst
              ? null
              : Border(top: BorderSide(color: tokens.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: widget.asCard ? _buildCard(context) : _buildRow(context),
      ),
    );
  }

  // ---- wide -------------------------------------------------------------

  Widget _buildRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: _Columns.provider,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _Identity(entry: widget.entry, tokens: widget.tokens),
          ),
        ),
        Expanded(
          flex: _Columns.apiKey,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Flexible(child: _maskedKey(context)),
                if (widget.isActive) ...[
                  const SizedBox(width: 10),
                  const _ActiveBadge(),
                ],
                if (widget.isTesting) ...[
                  const SizedBox(width: 10),
                  const _TestingSpinner(),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          flex: _Columns.model,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _model(context),
          ),
        ),
        Expanded(flex: _Columns.added, child: _added(context)),
        SizedBox(
          width: _Columns.actionsWidth,
          child: Align(alignment: Alignment.centerRight, child: _menu()),
        ),
      ],
    );
  }

  // ---- compact ----------------------------------------------------------

  /// The same four facts as the row, stacked: who the key is for, the key
  /// itself, then the two details that only matter once you have found it.
  Widget _buildCard(BuildContext context) {
    final tokens = widget.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Identity(entry: widget.entry, tokens: tokens),
            ),
            const SizedBox(width: 8),
            _menu(),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(child: _maskedKey(context)),
            if (widget.isActive) ...[
              const SizedBox(width: 8),
              const _ActiveBadge(),
            ],
            if (widget.isTesting) ...[
              const SizedBox(width: 8),
              const _TestingSpinner(),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _CardFact(
          label: LocaleKeys.aiColModel.tr().toUpperCase(),
          tokens: tokens,
          child: _model(context),
        ),
        const SizedBox(height: 4),
        _CardFact(
          label: LocaleKeys.aiColAdded.tr().toUpperCase(),
          tokens: tokens,
          child: _added(context),
        ),
      ],
    );
  }

  // ---- shared pieces ----------------------------------------------------

  Widget _maskedKey(BuildContext context) => Text(
    widget.entry.maskedKey,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: LingoDeskTheme.codeStyle.copyWith(
      color: widget.tokens.foreground,
      fontSize: 12,
    ),
  );

  Widget _model(BuildContext context) => Text(
    widget.entry.model,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: LingoDeskTheme.codeStyle.copyWith(
      color: widget.tokens.muted,
      fontSize: 12,
    ),
  );

  Widget _added(BuildContext context) => Text(
    DateFormatter.relative(widget.entry.createdAt),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: widget.tokens.muted, fontSize: 12),
  );

  Widget _menu() {
    return AnimatedOpacity(
      duration: LingoDeskMotion.fast,
      curve: LingoDeskMotion.curve,
      // Fully opaque without a pointer: there is no hover on a touch
      // screen to bring it up with.
      opacity: hasHover ? (_hovered ? 1 : 0.4) : 1,
      child: LingoDeskMenuButton<AiKeyAction>(
        tooltip: LocaleKeys.aiKeyActions.tr(),
        menuWidth: 210,
        items: [
          LingoDeskMenuItem(
            value: AiKeyAction.use,
            label: LocaleKeys.aiKeyUse.tr(),
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            enabled: !widget.isActive && widget.entry.isUsable,
          ),
          LingoDeskMenuItem(
            value: AiKeyAction.test,
            label: LocaleKeys.aiKeyTest.tr(),
            icon: HugeIcons.strokeRoundedPlugSocket,
            enabled: !widget.isTesting,
          ),
          LingoDeskMenuItem(
            value: AiKeyAction.edit,
            label: LocaleKeys.commonEdit.tr(),
            icon: HugeIcons.strokeRoundedEdit02,
          ),
          const LingoDeskMenuItem.divider(),
          LingoDeskMenuItem(
            value: AiKeyAction.delete,
            label: LocaleKeys.commonDelete.tr(),
            icon: HugeIcons.strokeRoundedDelete02,
            destructive: true,
          ),
        ],
        onSelected: widget.onAction,
      ),
    );
  }
}

/// The key's own name over the provider it belongs to, behind the
/// provider's logo.
class _Identity extends StatelessWidget {
  const _Identity({required this.entry, required this.tokens});

  final AiKey entry;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                entry.provider.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A labelled detail inside a card, standing in for the column header the
/// card no longer has.
class _CardFact extends StatelessWidget {
  const _CardFact({
    required this.label,
    required this.tokens,
    required this.child,
  });

  final String label;
  final LingoDeskTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _TestingSpinner extends StatelessWidget {
  const _TestingSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 13,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: LingoDeskTokens.of(context).accent,
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        LocaleKeys.aiKeyActive.tr(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tokens.accent,
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
          LocaleKeys.aiTableEmpty.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
        ),
      ),
    );
  }
}
