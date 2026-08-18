part of '../pages/app_dashboard_page.dart';

class _ProjectsTable extends StatelessWidget {
  const _ProjectsTable({required this.state});

  final AppManagementLoaded state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final overviews = state.filteredOverviews;

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
                        Expanded(
                          child: _CardHeader(
                            title: 'Apps',
                            subtitle:
                                state.query.trim().isEmpty
                                    ? 'Current localization workspaces'
                                    : '${overviews.length} of '
                                        '${state.overviews.length} apps match '
                                        '"${state.query.trim()}"',
                            icon: HugeIcons.strokeRoundedFolder02,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _openCreateApp(context),
                          icon: const LingoDeskIcon(
                            HugeIcons.strokeRoundedAdd01,
                            size: 17,
                          ),
                          label: const Text('New app'),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: tokens.border),
                  _TableHeader(tokens: tokens),
                  Divider(height: 1, color: tokens.border),
                  if (overviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Text(
                        'No apps match your search.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
                      ),
                    )
                  else
                    for (final overview in overviews) ...[
                      _ProjectRow(overview: overview),
                      if (overview != overviews.last)
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

  final LingoDeskTokens tokens;

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
  final LingoDeskTokens tokens;

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
  const _ProjectRow({required this.overview});

  final AppOverview overview;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final app = overview.app;
    final status = _statusOf(overview);

    return InkWell(
      onTap: () => _openEditor(context, overview),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${app.sourceLanguage}.json - ${overview.keyCount} keys',
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
                  for (final language in app.targetLanguages)
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
                      value: overview.progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(99),
                      color:
                          overview.isComplete
                              ? LingoDeskColors.complete
                              : LingoDeskColors.brandTeal,
                      backgroundColor: tokens.active,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(overview.progress * 100).round()}%',
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
                child: _Badge(label: status.label, color: status.color),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormatter.relative(overview.lastActivity),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
              ),
            ),
            _ProjectRowMenu(overview: overview, tokens: tokens),
          ],
        ),
      ),
    );
  }
}

class _ProjectRowMenu extends StatelessWidget {
  const _ProjectRowMenu({required this.overview, required this.tokens});

  final AppOverview overview;
  final LingoDeskTokens tokens;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: LingoDeskIcon(
        HugeIcons.strokeRoundedMoreHorizontal,
        color: tokens.muted,
      ),
      onSelected: (action) {
        switch (action) {
          case 'editor':
            _openEditor(context, overview);
          case 'settings':
            _openAppSettings(context, overview);
          case 'upload':
            _openFileUpload(context, overview);
          case 'delete':
            _confirmDeleteApp(context, overview);
        }
      },
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: 'editor',
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedTableRowsSplit,
                label: 'Open editor',
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedSettings01,
                label: 'Settings',
              ),
            ),
            PopupMenuItem(
              value: 'upload',
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedFileUpload,
                label: 'Upload files',
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: _MenuOption(
                icon: HugeIcons.strokeRoundedDelete02,
                label: 'Delete app',
              ),
            ),
          ],
    );
  }
}
