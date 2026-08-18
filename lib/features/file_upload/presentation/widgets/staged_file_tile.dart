import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../domain/entities/uploaded_translation_file.dart';

/// One staged upload row: file name, language badge, key count or error.
class StagedFileTile extends StatelessWidget {
  const StagedFileTile({super.key, required this.file, required this.onRemove});

  final UploadedTranslationFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final statusColor = file.isValid
        ? LingoDeskColors.complete
        : LingoDeskColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          LingoDeskIcon(
            file.isValid
                ? HugeIcons.strokeRoundedCheckmarkCircle02
                : HugeIcons.strokeRoundedAlertCircle,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.foreground,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  file.isValid ? '${file.keyCount} keys detected' : file.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: file.isValid ? tokens.muted : LingoDeskColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          WorkspaceBadge(
            label: file.languageCode.toUpperCase(),
            color: file.isValid ? tokens.muted : LingoDeskColors.error,
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
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
}
