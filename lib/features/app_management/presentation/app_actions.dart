import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/lingo_desk_theme.dart';
import '../../../core/theme/lingo_desk_tokens.dart';
import '../../app_settings/presentation/widgets/create_app_dialog.dart';
import '../domain/entities/app_overview.dart';
import 'bloc/app_management_bloc.dart';
import 'bloc/app_management_event.dart';

/// Navigation and dialog helpers shared by the shell sidebar, the apps
/// table and the dashboard. They all read the shell-scoped
/// [AppManagementBloc], so any caller must sit below [AppShell].
Future<void> openCreateApp(BuildContext context) async {
  final app = await CreateAppDialog.show(context);
  if (app == null || !context.mounted) {
    return;
  }

  // Offer to import files right away; the stats refresh via the page's
  // RouteAware.didPopNext when the dialogs close.
  final uploadNow = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('"${app.name}" created'),
      content: const Text(
        'Do you want to upload your existing JSON translation files now? '
        'You can also do this later from the dashboard.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Upload files'),
        ),
      ],
    ),
  );

  if (uploadNow == true && context.mounted) {
    context.push(AppRoutes.fileUpload(app.id), extra: app);
  }
}

/// Opens the project import page, which creates the app from a scanned
/// folder rather than asking for an app up front.
void openImportProject(BuildContext context) {
  context.push(AppRoutes.importProject);
}

void openAppSettings(BuildContext context, AppOverview overview) {
  context.push(AppRoutes.appSettings(overview.app.id), extra: overview.app);
}

void openFileUpload(BuildContext context, AppOverview overview) {
  context.push(AppRoutes.fileUpload(overview.app.id), extra: overview.app);
}

void openEditor(BuildContext context, AppOverview overview) {
  context.push(AppRoutes.editor(overview.app.id));
}

Future<void> confirmDeleteApp(
  BuildContext context,
  AppOverview overview,
) async {
  final bloc = context.read<AppManagementBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete "${overview.app.name}"?'),
      content: const Text(
        'This permanently removes the app and all of its translations. '
        'This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: LingoDeskColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) {
    bloc.add(DeleteAppEvent(overview.app.id));
  }
}

/// Derived status of an app for the apps table. Takes [tokens] rather
/// than a context so the "New" badge follows the active theme variant.
({String label, Color color}) appStatusOf(
  AppOverview overview,
  LingoDeskTokens tokens,
) {
  if (overview.keyCount == 0) {
    return (label: 'New', color: tokens.accent);
  }
  if (overview.isComplete) {
    return (label: 'Complete', color: LingoDeskColors.complete);
  }
  return (label: 'Missing', color: LingoDeskColors.warning);
}
