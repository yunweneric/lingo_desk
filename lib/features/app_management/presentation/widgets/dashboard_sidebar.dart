part of '../pages/app_dashboard_page.dart';

class _AppSidebar extends StatelessWidget {
  const _AppSidebar();

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.sidebar,
        border: Border(right: BorderSide(color: tokens.border)),
      ),
      child: SizedBox(
        width: 284,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                  child: LingoDeskMark(
                    size: 34,
                    reversed: tokens.isDark,
                    showWordmark: true,
                  ),
                ),
                const _SidebarSection(
                  title: 'Platform',
                  items: [
                    _SidebarItemData(
                      label: 'Dashboard',
                      icon: HugeIcons.strokeRoundedDashboardSquare01,
                      isActive: true,
                    ),
                    _SidebarItemData(
                      label: 'Apps',
                      icon: HugeIcons.strokeRoundedFolder02,
                    ),
                    _SidebarItemData(
                      label: 'Imports',
                      icon: HugeIcons.strokeRoundedFileUpload,
                    ),
                    _SidebarItemData(
                      label: 'Editor',
                      icon: HugeIcons.strokeRoundedTableRowsSplit,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _SidebarSection(
                  title: 'Tools',
                  items: [
                    _SidebarItemData(
                      label: 'Languages',
                      icon: HugeIcons.strokeRoundedLanguageSquare,
                    ),
                    _SidebarItemData(
                      label: 'Settings',
                      icon: HugeIcons.strokeRoundedSettings01,
                    ),
                  ],
                ),
                const Spacer(),
                _SidebarFooter(tokens: tokens),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.title, required this.items});

  final String title;
  final List<_SidebarItemData> items;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: tokens.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final item in items) _SidebarItem(item: item),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item});

  final _SidebarItemData item;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: item.isActive ? tokens.active : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              LingoDeskIcon(
                item.icon,
                size: 18,
                color: item.isActive ? tokens.foreground : tokens.muted,
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: item.isActive ? tokens.foreground : tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.tokens});

  final _DashboardTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LingoDeskColors.brandBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'LD',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local workspace',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Browser storage',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: tokens.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          LingoDeskIcon(
            HugeIcons.strokeRoundedMoreHorizontal,
            size: 18,
            color: tokens.muted,
          ),
        ],
      ),
    );
  }
}
