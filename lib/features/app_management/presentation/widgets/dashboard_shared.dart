part of '../pages/app_dashboard_page.dart';

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return Row(
      children: [
        LingoDeskIcon(icon, color: tokens.muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = _DashboardTokens.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(78)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DashboardTokens {
  const _DashboardTokens({
    required this.isDark,
    required this.background,
    required this.sidebar,
    required this.card,
    required this.border,
    required this.foreground,
    required this.muted,
    required this.active,
  });

  final bool isDark;
  final Color background;
  final Color sidebar;
  final Color card;
  final Color border;
  final Color foreground;
  final Color muted;
  final Color active;

  static _DashboardTokens of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _DashboardTokens(
      isDark: isDark,
      background: isDark ? LingoDeskColors.darkInk : LingoDeskColors.surface,
      sidebar: isDark ? const Color(0xFF080D16) : Colors.white,
      card: isDark ? LingoDeskColors.darkSurface : Colors.white,
      border: isDark ? Colors.white12 : LingoDeskColors.border,
      foreground: isDark ? Colors.white : LingoDeskColors.ink,
      muted: isDark ? LingoDeskColors.slateLight : LingoDeskColors.slate,
      active: isDark ? const Color(0xFF151B27) : const Color(0xFFF1F5F9),
    );
  }
}
