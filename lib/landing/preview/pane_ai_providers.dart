import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/theme/lingo_desk_motion.dart';
import '../../core/theme/lingo_desk_theme.dart';
import '../../core/theme/lingo_desk_tokens.dart';
import '../../core/widgets/lingo_desk_icon.dart';
import 'preview_chrome.dart';
import 'preview_workspace.dart';

/// Bring your own key. Clicking a row makes it the active key, which the
/// banner above and the editor's AI action both follow; the eye reveals
/// the masked value.
class PreviewAiProvidersPane extends StatelessWidget {
  const PreviewAiProvidersPane({super.key, required this.workspace});

  final PreviewWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final active = workspace.activeProvider;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PreviewBreadcrumb(
            segments: ['Workspace', 'Settings', 'AI providers'],
            actions: [
              PreviewButton(
                label: 'Add API key',
                icon: HugeIcons.strokeRoundedAdd01,
                primary: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tokens.brandFill,
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
              border: Border.all(color: tokens.brandFillBorder),
            ),
            child: Row(
              children: [
                LingoDeskIcon(
                  HugeIcons.strokeRoundedSparkles,
                  size: 24,
                  color: tokens.onBrandFill,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Translating with ${active.name}',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: tokens.onBrandFill,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${active.name} · ${active.model} · used by every '
                        'AI action in the editor.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: tokens.onBrandFill.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
              border: Border.all(color: tokens.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius - 1),
              child: Column(
                children: [
                  const PreviewTableHeader(
                    cells: [
                      (26, 'PROVIDER'),
                      (28, 'API KEY'),
                      (26, 'MODEL'),
                      (20, 'ADDED'),
                    ],
                  ),
                  for (final provider in PreviewWorkspace.providers)
                    _ProviderRow(
                      provider: provider,
                      workspace: workspace,
                      last: provider == PreviewWorkspace.providers.last,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              LingoDeskIcon(
                HugeIcons.strokeRoundedInformationCircle,
                size: 17,
                color: tokens.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keys live in the OS secure store. They stay on this '
                  'device and are only ever sent to the provider they '
                  'belong to.',
                  style: TextStyle(fontSize: 12.5, color: tokens.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatefulWidget {
  const _ProviderRow({
    required this.provider,
    required this.workspace,
    required this.last,
  });

  final PreviewProvider provider;
  final PreviewWorkspace workspace;
  final bool last;

  @override
  State<_ProviderRow> createState() => _ProviderRowState();
}

class _ProviderRowState extends State<_ProviderRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final provider = widget.provider;
    final active = widget.workspace.activeProviderId == provider.id;
    final revealed = widget.workspace.revealedKeyId == provider.id;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.workspace.setActiveProvider(provider.id),
        child: AnimatedContainer(
          duration: LingoDeskMotion.fast,
          curve: LingoDeskMotion.curve,
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _hovered ? tokens.active : Colors.transparent,
            border: widget.last
                ? null
                : Border(bottom: BorderSide(color: tokens.border)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 26,
                child: Row(
                  children: [
                    LingoDeskIcon(
                      HugeIcons.strokeRoundedSparkles,
                      size: 20,
                      color: active ? tokens.accent : tokens.muted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.foreground,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 28,
                child: Row(
                  children: [
                    // Masked by default, like the real table. The reveal
                    // shows an obviously fake key, and gives way to the
                    // toggle and the Active pill rather than pushing them
                    // out of the column.
                    Flexible(
                      child: Text(
                        revealed
                            ? 'sk-preview-0000-not-a-real-key'
                            : '••••••••••••••••',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LingoDeskTheme.codeStyle.copyWith(
                          color: tokens.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Reveal(
                      revealed: revealed,
                      onTap: () => widget.workspace.toggleReveal(provider.id),
                    ),
                    if (active) ...[
                      const SizedBox(width: 10),
                      const WorkspaceBadgeActive(),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 26,
                child: Text(
                  provider.model,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.foreground,
                    fontSize: 12.5,
                  ),
                ),
              ),
              Expanded(
                flex: 20,
                child: Text(
                  provider.added,
                  style: TextStyle(fontSize: 12.5, color: tokens.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Active" pill, in the brand of whatever palette is showing.
class WorkspaceBadgeActive extends StatelessWidget {
  const WorkspaceBadgeActive({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.brandFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.brandFillBorder),
      ),
      child: Text(
        'Active',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: tokens.onBrandFill,
        ),
      ),
    );
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.revealed, required this.onTap});

  final bool revealed;
  final VoidCallback onTap;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        // Swallowed so revealing a key does not also change which key is
        // active — two different intentions on one row.
        onTap: widget.onTap,
        child: SizedBox.square(
          dimension: 26,
          child: Center(
            child: LingoDeskIcon(
              widget.revealed
                  ? HugeIcons.strokeRoundedViewOff
                  : HugeIcons.strokeRoundedView,
              size: 16,
              color: _hovered ? tokens.accent : tokens.muted,
            ),
          ),
        ),
      ),
    );
  }
}
