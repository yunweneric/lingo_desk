import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/workspace_card.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../bloc/app_management_state.dart';

/// Workspace-wide counters and the overall translation-file progress,
/// shown above the apps table.
class AppsSummaryCard extends StatelessWidget {
  const AppsSummaryCard({super.key, required this.state});

  final AppManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final missing = state.totalMissing;
    final coverage = state.coverage;

    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: WorkspaceCardHeader(
                  title: 'Workspace totals',
                  subtitle: 'Translation files across every app and locale',
                  icon: HugeIcons.strokeRoundedChartBarIncreasing,
                ),
              ),
              WorkspaceBadge(
                label: missing == 0 ? 'All clear' : '$missing missing',
                color: missing == 0
                    ? LingoDeskColors.complete
                    : LingoDeskColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(coverage * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 34, height: 1),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'overall coverage',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WorkspaceProgressBar(
            value: coverage,
            isComplete: state.totalCells > 0 && missing == 0,
            minHeight: 10,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WorkspaceMetaTile(
                label: 'Apps',
                value: state.overviews.length.toString(),
                icon: HugeIcons.strokeRoundedFolder02,
                width: 150,
              ),
              WorkspaceMetaTile(
                label: 'Files complete',
                value: '${state.completeFiles}/${state.totalFiles}',
                icon: HugeIcons.strokeRoundedFileUpload,
                width: 150,
              ),
              WorkspaceMetaTile(
                label: 'Total keys',
                value: state.totalKeys.toString(),
                icon: HugeIcons.strokeRoundedKey01,
                width: 150,
              ),
              WorkspaceMetaTile(
                label: 'Missing strings',
                value: missing.toString(),
                icon: HugeIcons.strokeRoundedAlertCircle,
                width: 150,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
