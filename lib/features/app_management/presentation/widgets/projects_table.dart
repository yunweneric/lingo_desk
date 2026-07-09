part of '../pages/app_dashboard_page.dart';

class _ProjectsTable extends StatelessWidget {
  const _ProjectsTable({required this.projects});

  final List<_ProjectSummary> projects;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth =
            constraints.maxWidth < 860 ? 860.0 : constraints.maxWidth;

        return _Surface(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: _CardHeader(
                            title: 'Apps',
                            subtitle: 'Current localization workspaces',
                            icon: HugeIcons.strokeRoundedFolder02,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const LingoDeskIcon(
                            HugeIcons.strokeRoundedFilterHorizontal,
                            size: 17,
                          ),
                          label: const Text('Filter'),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: tokens.border),
                  _TableHeader(tokens: tokens),
                  Divider(height: 1, color: tokens.border),
                  for (final project in projects) ...[
                    _ProjectRow(project: project),
                    if (project != projects.last)
                      Divider(height: 1, color: tokens.border),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.tokens});

  final _DashboardTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _HeaderCell('App', flex: 4, tokens: tokens),
          _HeaderCell('Languages', flex: 3, tokens: tokens),
          _HeaderCell('Progress', flex: 3, tokens: tokens),
          _HeaderCell('Status', flex: 2, tokens: tokens),
          _HeaderCell('Updated', flex: 2, tokens: tokens),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex, required this.tokens});

  final String label;
  final int flex;
  final _DashboardTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: tokens.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});

  final _ProjectSummary project;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${project.sourceLanguage}.json - ${project.keyCount} keys',
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final language in project.targetLanguages)
                  _Badge(label: language.toUpperCase(), color: tokens.muted),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: project.progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                    color:
                        project.missingCount == 0
                            ? LingoDeskColors.complete
                            : LingoDeskColors.brandBlue,
                    backgroundColor: tokens.active,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(project.progress * 100).round()}%',
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.foreground,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Badge(
                label: project.status,
                color:
                    project.missingCount == 0
                        ? LingoDeskColors.complete
                        : LingoDeskColors.warning,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              project.updatedLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
            ),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: () {},
            icon: LingoDeskIcon(
              HugeIcons.strokeRoundedMoreHorizontal,
              color: tokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}
