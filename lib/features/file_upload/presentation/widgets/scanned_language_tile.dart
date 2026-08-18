import 'package:flutter/material.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/theme/lingo_desk_motion.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_checkbox.dart';
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
    this.exportPath,
  });

  final ScannedLanguageGroup group;

  /// Keys across every detected language, so the bars are comparable.
  final int totalKeys;

  final bool isIncluded;
  final bool isSource;
  final VoidCallback? onToggle;

  /// Path an export writes this language back to, relative to the
  /// project root. Only worth showing when it is not simply the file the
  /// language was read from.
  final String? exportPath;

  /// True when the export path is not one of the files scanned, i.e. the
  /// language came from several files and collapses into one.
  bool get _mergesOnExport =>
      exportPath != null && !group.relativePaths.contains(exportPath);

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

    // Excluding a locale is reversible and easy to do by accident, so the
    // tile dims and its accent border drains away rather than blinking
    // between two states.
    return AnimatedOpacity(
      opacity: isIncluded ? 1 : 0.55,
      duration: LingoDeskMotion.standard,
      curve: LingoDeskMotion.curve,
      child: AnimatedContainer(
        duration: LingoDeskMotion.standard,
        curve: LingoDeskMotion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isIncluded ? accent.withValues(alpha: 0.45) : tokens.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LingoDeskCheckbox(
                  value: isIncluded,
                  semanticLabel: SupportedLanguages.nameOf(group.languageCode),
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
                AnimatedDefaultTextStyle(
                  duration: LingoDeskMotion.standard,
                  curve: LingoDeskMotion.curve,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: accent,
                    fontSize: 12,
                  ),
                  child: Text('${group.filledKeyCount}/$totalKeys'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.toDouble()),
                duration: LingoDeskMotion.slow,
                curve: LingoDeskMotion.entrance,
                builder: (context, animated, _) {
                  return TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: accent),
                    duration: LingoDeskMotion.standard,
                    curve: LingoDeskMotion.curve,
                    builder: (context, color, _) {
                      return LinearProgressIndicator(
                        value: animated,
                        minHeight: 6,
                        backgroundColor: tokens.active,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          color ?? accent,
                        ),
                      );
                    },
                  );
                },
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
            // Several files merge into one on the way back out, so the
            // destination is called out before the import, not after.
            if (_mergesOnExport) ...[
              const SizedBox(height: 8),
              Text(
                'Exports back to $exportPath',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LingoDeskTheme.codeStyle.copyWith(
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
