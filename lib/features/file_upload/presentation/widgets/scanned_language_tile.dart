import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../domain/entities/scanned_project.dart';

/// One detected language in a scanned project: where it came from, how
/// complete it is, and whether it will be imported.
class ScannedLanguageTile extends StatelessWidget {
  const ScannedLanguageTile({
    super.key,
    required this.group,
    required this.totalKeys,
    required this.isIncluded,
    required this.isSource,
    required this.onToggle,
  });

  final ScannedLanguageGroup group;

  /// Keys across every detected language, so the bars are comparable.
  final int totalKeys;

  final bool isIncluded;
  final bool isSource;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final progress =
        totalKeys == 0
            ? 0.0
            : (group.filledKeyCount / totalKeys).clamp(0.0, 1.0);
    final accent =
        !isIncluded
            ? tokens.muted
            : progress == 1
            ? LingoDeskColors.complete
            : LingoDeskColors.brandTeal;

    return Opacity(
      opacity: isIncluded ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isIncluded,
                  // The source language is always part of the import.
                  onChanged: onToggle == null ? null : (_) => onToggle!(),
                ),
                Text(
                  SupportedLanguages.flagOf(group.languageCode),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            SupportedLanguages.nameOf(group.languageCode),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          if (isSource) ...[
                            const SizedBox(width: 8),
                            const WorkspaceBadge(
                              label: 'SOURCE',
                              color: LingoDeskColors.brandTeal,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        group.relativePaths.join('   •   '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LingoDeskTheme.codeStyle.copyWith(
                          color: tokens.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${group.filledKeyCount}/$totalKeys',
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: accent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: tokens.active,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            if (group.conflictCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${group.conflictCount} duplicate key(s) merged across '
                '${group.relativePaths.length} files.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
