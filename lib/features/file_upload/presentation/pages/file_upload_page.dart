import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../app_management/domain/entities/app.dart';
import '../bloc/file_upload_bloc.dart';
import '../bloc/file_upload_event.dart';
import '../bloc/file_upload_state.dart';
import '../widgets/staged_file_tile.dart';

/// Import existing JSON translation files into an app's workspace.
class FileUploadPage extends StatelessWidget {
  const FileUploadPage({
    super.key,
    required this.app,
    this.popOnImport = false,
  });

  final App app;

  /// When true (opened from the editor), a successful import pops back
  /// instead of pushing a new editor page.
  final bool popOnImport;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FileUploadBloc>()..add(LoadUploadContextEvent(app)),
      child: BlocConsumer<FileUploadBloc, FileUploadState>(
        listener: (context, state) {
          if (state is FileUploadImportSuccess) {
            if (popOnImport) {
              context.pop(true);
            } else {
              context.pushReplacement(AppRoutes.editor(state.app.id));
            }
          }
        },
        builder: (context, state) {
          final ready = state is FileUploadReady ? state : null;

          return WorkspaceScaffold(
            title: 'Upload files',
            subtitle: app.name,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child:
                      ready == null
                          ? const Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: CircularProgressIndicator(),
                          )
                          : _UploadBody(state: ready, popOnImport: popOnImport),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UploadBody extends StatelessWidget {
  const _UploadBody({required this.state, required this.popOnImport});

  final FileUploadReady state;
  final bool popOnImport;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final app = state.app;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required languages',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Name each file after its language code (e.g. '
                '${app.sourceLanguage}.json). Files outside this set are '
                'rejected.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final language in app.allLanguages)
                    _LanguageChip(
                      language: language,
                      isSource: language == app.sourceLanguage,
                      isCovered: state.coveredLanguages.contains(language),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        WorkspaceSurface(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: LingoDeskColors.brandTeal.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const LingoDeskIcon(
                  HugeIcons.strokeRoundedFileUpload,
                  color: LingoDeskColors.brandTeal,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Add your translation files',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                'Select one or more .json files exported from your codebase.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed:
                    state.isImporting
                        ? null
                        : () => context.read<FileUploadBloc>().add(
                          PickFilesEvent(),
                        ),
                icon: const LingoDeskIcon(
                  HugeIcons.strokeRoundedFolderAdd,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text('Browse files'),
              ),
            ],
          ),
        ),
        if (state.stagedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Staged files', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          for (final file in state.stagedFiles) ...[
            StagedFileTile(
              file: file,
              onRemove:
                  () => context.read<FileUploadBloc>().add(
                    RemoveFileEvent(file.fileName),
                  ),
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const LingoDeskIcon(
                HugeIcons.strokeRoundedAlertCircle,
                size: 18,
                color: LingoDeskColors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LingoDeskColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed:
                  state.isImporting
                      ? null
                      : () {
                        if (popOnImport) {
                          context.pop(false);
                        } else {
                          context.pushReplacement(AppRoutes.editor(app.id));
                        }
                      },
              child: Text(popOnImport ? 'Back to editor' : 'Skip to editor'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed:
                  state.canImport
                      ? () => context.read<FileUploadBloc>().add(
                        ConfirmImportEvent(),
                      )
                      : null,
              icon:
                  state.isImporting
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const LingoDeskIcon(
                        HugeIcons.strokeRoundedArrowRight01,
                        color: Colors.white,
                        size: 18,
                      ),
              label: const Text('Import & open editor'),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.language,
    required this.isSource,
    required this.isCovered,
  });

  final String language;
  final bool isSource;
  final bool isCovered;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final color = isCovered ? LingoDeskColors.complete : tokens.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LingoDeskIcon(
            isCovered
                ? HugeIcons.strokeRoundedCheckmarkCircle02
                : HugeIcons.strokeRoundedCircle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '${language.toUpperCase()}'
            '${isSource ? ' - source' : ''}'
            ' (${SupportedLanguages.nameOf(language)})',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isCovered ? color : tokens.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
