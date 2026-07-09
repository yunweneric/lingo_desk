import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_mark.dart';

part '../widgets/dashboard_cards.dart';
part '../widgets/dashboard_content.dart';
part '../widgets/dashboard_controls.dart';
part '../widgets/dashboard_header.dart';
part '../widgets/dashboard_shared.dart';
part '../widgets/dashboard_sidebar.dart';
part '../widgets/projects_table.dart';

class AppDashboardPage extends StatelessWidget {
  const AppDashboardPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;

  static const _projects = [
    _ProjectSummary(
      name: 'Customer Portal',
      sourceLanguage: 'en',
      targetLanguages: ['fr', 'es', 'uk'],
      keyCount: 148,
      missingCount: 12,
      updatedLabel: '2 min ago',
      progress: 0.92,
      status: 'In review',
    ),
    _ProjectSummary(
      name: 'Admin Console',
      sourceLanguage: 'en',
      targetLanguages: ['fr', 'de'],
      keyCount: 86,
      missingCount: 19,
      updatedLabel: 'Yesterday',
      progress: 0.78,
      status: 'Missing',
    ),
    _ProjectSummary(
      name: 'Mobile App',
      sourceLanguage: 'en',
      targetLanguages: ['fr', 'es', 'pt', 'uk'],
      keyCount: 213,
      missingCount: 0,
      updatedLabel: '3 days ago',
      progress: 1,
      status: 'Complete',
    ),
    _ProjectSummary(
      name: 'Marketing Site',
      sourceLanguage: 'en',
      targetLanguages: ['fr', 'es'],
      keyCount: 64,
      missingCount: 8,
      updatedLabel: '5 days ago',
      progress: 0.88,
      status: 'Draft',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1024;

          return Row(
            children: [
              if (isWide) const _AppSidebar(),
              Expanded(
                child: _DashboardContent(
                  projects: _projects,
                  themeMode: themeMode,
                  onThemeModeChanged: onThemeModeChanged,
                  selectedLanguage: selectedLanguage,
                  onLanguageChanged: onLanguageChanged,
                  showMobileBrand: !isWide,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

List<_Metric> _dashboardMetrics(List<_ProjectSummary> projects) {
  final totalKeys = projects.fold<int>(0, (sum, app) => sum + app.keyCount);
  final missing = projects.fold<int>(0, (sum, app) => sum + app.missingCount);
  final complete = totalKeys - missing;
  final coverage = totalKeys == 0 ? 0 : complete / totalKeys;

  return [
    _Metric(
      label: 'Apps',
      value: projects.length.toString(),
      detail: '+1 this month',
      icon: HugeIcons.strokeRoundedFolder02,
    ),
    _Metric(
      label: 'Total keys',
      value: totalKeys.toString(),
      detail: 'Across active apps',
      icon: HugeIcons.strokeRoundedKey01,
    ),
    _Metric(
      label: 'Coverage',
      value: '${(coverage * 100).round()}%',
      detail: '+4.2% from last sync',
      icon: HugeIcons.strokeRoundedChartBarIncreasing,
    ),
    _Metric(
      label: 'Missing',
      value: missing.toString(),
      detail: missing == 0 ? 'All clear' : 'Needs review',
      icon: HugeIcons.strokeRoundedAlertCircle,
      isPositive: missing == 0,
    ),
  ];
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.isPositive = true,
  });

  final String label;
  final String value;
  final String detail;
  final List<List<dynamic>> icon;
  final bool isPositive;
}

class _SidebarItemData {
  const _SidebarItemData({
    required this.label,
    required this.icon,
    this.isActive = false,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool isActive;
}

class _ProjectSummary {
  const _ProjectSummary({
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguages,
    required this.keyCount,
    required this.missingCount,
    required this.updatedLabel,
    required this.progress,
    required this.status,
  });

  final String name;
  final String sourceLanguage;
  final List<String> targetLanguages;
  final int keyCount;
  final int missingCount;
  final String updatedLabel;
  final double progress;
  final String status;
}
