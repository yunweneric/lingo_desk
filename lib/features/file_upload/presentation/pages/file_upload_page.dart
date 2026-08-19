import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/lingo_desk_theme.dart';
import '../../../../core/theme/lingo_desk_tokens.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/language_dropdown.dart';
import '../../../../core/widgets/lingo_desk_animations.dart';
import '../../../../core/widgets/lingo_desk_field.dart';
import '../../../../core/widgets/lingo_desk_icon.dart';
import '../../../../core/widgets/lingo_desk_text_field.dart';
import '../../../../core/widgets/lingo_desk_toast.dart';
import '../../../../core/widgets/workspace_page_header.dart';
import '../../../../core/widgets/workspace_scaffold.dart';
import '../../../app_management/domain/entities/app.dart';
import '../../domain/entities/scanned_project.dart';
import '../bloc/file_upload_bloc.dart';
import '../bloc/file_upload_event.dart';
import '../bloc/file_upload_state.dart';
import '../widgets/scanned_language_tile.dart';
import '../widgets/staged_file_tile.dart';
import '../../../../core/localization/export.dart';

/// Bring existing JSON translation files into LingoDesk.
///
/// Two modes. With an [app] it fills that app's workspace: pick files or
/// scan a folder, and anything outside the app's languages is rejected.
/// Without one it is project mode — point it at a codebase, it finds the
/// translation files itself, and importing creates the app from the
/// folder name.
class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key, this.app, this.popOnImport = false});

  /// The app being imported into, or null to import a whole project.
  final App? app;

  /// When true (opened from the editor), a successful import pops back
  /// instead of pushing a new editor page.
  final bool popOnImport;

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  /// Owned here rather than rebuilt from state, so typing in the name
  /// field does not fight the cursor.
  final _nameController = TextEditingController();

  bool get _isProjectMode => widget.app == null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<FileUploadBloc>()..add(LoadUploadContextEvent(widget.app)),
      child: BlocConsumer<FileUploadBloc, FileUploadState>(
        listener: (context, state) {
          if (state is FileUploadReady) {
            // Typing keeps the two in sync, so they only diverge when a
            // scan seeds the name or a reset clears it.
            final name = state.projectName ?? '';
            if (_nameController.text != name) {
              _nameController.text = name;
            }
          }
          if (state is FileUploadImportSuccess) {
            context.showSuccessToast(
              LocaleKeys.uploadImportedToast.tr(
                namedArgs: {'name': state.app.name},
              ),
            );
            if (widget.popOnImport) {
              context.pop(true);
            } else {
              context.pushReplacement(AppRoutes.editor(state.app.id));
            }
          }
        },
        builder: (context, state) {
          final tokens = LingoDeskTokens.of(context);
          final ready = state is FileUploadReady ? state : null;

          return ColoredBox(
            color: tokens.background,
            child: SafeArea(
              child: Column(
                children: [
                  WorkspacePageHeader(
                    // Importing into an existing app hangs off Apps;
                    // a fresh project import is a top-level page.
                    breadcrumb: [
                      Crumb.workspace,
                      if (widget.app case final app?) ...[
                        Crumb(LocaleKeys.navApps.tr(), route: AppRoutes.apps),
                        Crumb(app.name),
                        Crumb(LocaleKeys.navImport.tr()),
                      ] else
                        Crumb(LocaleKeys.navImport.tr()),
                    ],
                    actions: [
                      OutlinedButton(
                        onPressed: ready == null || ready.isBusy
                            ? null
                            : () => _leave(context),
                        child: Text(_leaveLabel),
                      ),
                      FilledButton.icon(
                        onPressed: ready != null && ready.canImport
                            ? () => context.read<FileUploadBloc>().add(
                                ConfirmImportEvent(),
                              )
                            : null,
                        icon: ready != null && ready.isImporting
                            ? const SizedBox.square(
                                dimension: 16,
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
                        label: Text(
                          _isProjectMode
                              ? LocaleKeys.appsImportProject.tr()
                              : LocaleKeys.uploadImportAndOpen.tr(),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ready == null
                        ? const Center(child: CircularProgressIndicator())
                        : _UploadBody(
                            state: ready,
                            nameController: _nameController,
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String get _leaveLabel {
    if (_isProjectMode) {
      return LocaleKeys.uploadBackToApps.tr();
    }
    return widget.popOnImport
        ? LocaleKeys.uploadBackToEditor.tr()
        : LocaleKeys.uploadSkipToEditor.tr();
  }

  void _leave(BuildContext context) {
    if (_isProjectMode) {
      context.go(AppRoutes.apps);
    } else if (widget.popOnImport) {
      context.pop(false);
    } else {
      context.pushReplacement(AppRoutes.editor(widget.app!.id));
    }
  }
}

class _UploadBody extends StatelessWidget {
  const _UploadBody({required this.state, required this.nameController});

  final FileUploadReady state;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final isEmpty = state.isProjectMode
        ? !state.hasProject
        : state.stagedFiles.isEmpty;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isEmpty ? 620 : 760),
      child: isEmpty
          ? _EmptyState(state: state)
          : state.isProjectMode
          ? _ScannedProjectState(state: state, nameController: nameController)
          : _StagedState(state: state),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            // With nothing to import there is one thing to do, so the card
            // sits in the middle of the page rather than clinging to the
            // top of a mostly empty screen. A bare Center cannot do this
            // inside a scroll view: the viewport takes its child's own
            // height, so there is no slack to centre within. Floor the
            // child at the viewport height (minus this padding) and the
            // Center has room to work, while longer content still scrolls.
            constraints: BoxConstraints(
              minHeight: isEmpty ? constraints.maxHeight - 48 : 0,
            ),
            child: isEmpty
                ? Center(child: content)
                : Align(alignment: Alignment.topCenter, child: content),
          ),
        );
      },
    );
  }
}

/// Nothing to import yet: one centred card carrying the only action on
/// the page, with the naming contract spelled out underneath it.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state});

  final FileUploadReady state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final isProject = state.isProjectMode;

    return Column(
      children: [
        WorkspaceSurface(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.accent.withAlpha(26),
                  borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
                ),
                child: LingoDeskIcon(
                  isProject
                      ? HugeIcons.strokeRoundedFolder02
                      : HugeIcons.strokeRoundedFileUpload,
                  color: tokens.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isProject
                    ? LocaleKeys.uploadHeroProjectTitle.tr()
                    : LocaleKeys.uploadHeroFilesTitle.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                isProject
                    ? LocaleKeys.uploadHeroProjectBody.tr()
                    : LocaleKeys.uploadHeroFilesBody.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.muted),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => context.read<FileUploadBloc>().add(
                            ScanProjectEvent(),
                          ),
                    icon: state.isScanning
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const LingoDeskIcon(
                            HugeIcons.strokeRoundedFolderAdd,
                            color: Colors.white,
                            size: 18,
                          ),
                    label: Text(
                      state.isScanning
                          ? LocaleKeys.uploadScanning.tr()
                          : LocaleKeys.uploadChooseFolder.tr(),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => context.read<FileUploadBloc>().add(
                            PickFilesEvent(),
                          ),
                    icon: const LingoDeskIcon(
                      HugeIcons.strokeRoundedFileUpload,
                      size: 18,
                    ),
                    label: Text(LocaleKeys.uploadBrowseFiles.tr()),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Divider(color: tokens.border, height: 1),
              const SizedBox(height: 24),
              if (isProject)
                const _ScanContract()
              else
                _LanguageChecklist(state: state, centered: true),
            ],
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 14),
          _ErrorRow(message: state.errorMessage!),
        ],
      ],
    );
  }
}

/// What the folder scan looks for, so an empty result is explainable.
class _ScanContract extends StatelessWidget {
  const _ScanContract();

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      children: [
        Text(
          LocaleKeys.uploadWhereWeLook.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text(
          LocaleKeys.uploadWhereWeLookBody.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final example in const [
              'translations/en.json',
              'lib/languages/fr.json',
              'src/translations/de/common.json',
            ])
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: tokens.active,
                  borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
                  border: Border.all(color: tokens.border),
                ),
                child: Text(
                  example,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.foreground,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A scanned project: what will be created, then what will go into it.
class _ScannedProjectState extends StatelessWidget {
  const _ScannedProjectState({
    required this.state,
    required this.nameController,
  });

  final FileUploadReady state;
  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final project = state.project!;
    final totalKeys = project.allKeys.length;
    final included = state.includedGroups;
    final source = state.selectedSource ?? project.suggestedSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProjectIconField(
                    state: state,
                    nameController: nameController,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LingoDeskTextField(
                      controller: nameController,
                      label: LocaleKeys.appSettingsAppName.tr(),
                      hintText: LocaleKeys.appSettingsAppNameHint.tr(),
                      size: LingoDeskFieldSize.large,
                      enabled: !state.isBusy,
                      isRequired: true,
                      onChanged: (value) => context.read<FileUploadBloc>().add(
                        ProjectNameChangedEvent(value),
                      ),
                    ),
                  ),
                ],
              ),
              if (project.rootPath.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  // Kept on the app, so exports can go straight back here.
                  project.rootPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LingoDeskTheme.codeStyle.copyWith(
                    color: tokens.muted,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      label: LocaleKeys.appsTableColLanguages.tr(),
                      value: '${included.length}',
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: LocaleKeys.dashboardStatKeys.tr(),
                      value: '$totalKeys',
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: LocaleKeys.uploadStatTranslated.tr(),
                      value: _coverageLabel(included, totalKeys),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LanguageDropdown(
                label: LocaleKeys.appSettingsSourceLanguage.tr(),
                helperText: LocaleKeys.uploadSourceHelper.tr(),
                languageCodes: [
                  for (final group in project.groups) group.languageCode,
                ],
                value: source,
                enabled: !state.isBusy,
                onChanged: (value) => context.read<FileUploadBloc>().add(
                  SourceLanguageSelectedEvent(value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          LocaleKeys.uploadDetectedLanguages.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          LocaleKeys.uploadDetectedLanguagesHint.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        // A scan can turn up a dozen locales at once; letting them land in
        // sequence makes the result readable instead of a wall.
        for (var index = 0; index < project.groups.length; index++) ...[
          FadeSlideIn.staggered(
            index: index,
            child: ScannedLanguageTile(
              group: project.groups[index],
              totalKeys: totalKeys,
              isIncluded: !state.excludedLanguages.contains(
                project.groups[index].languageCode,
              ),
              isSource: project.groups[index].languageCode == source,
              exportPath: state
                  .scannedSource
                  ?.languageFiles[project.groups[index].languageCode],
              onToggle:
                  project.groups[index].languageCode == source || state.isBusy
                  ? null
                  : () => context.read<FileUploadBloc>().add(
                      ToggleScannedLanguageEvent(
                        project.groups[index].languageCode,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (project.skipped.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SkippedFiles(skipped: project.skipped),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 14),
          _ErrorRow(message: state.errorMessage!),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                included.isEmpty
                    ? LocaleKeys.uploadKeepOneLanguage.tr()
                    : LocaleKeys.uploadReadySummary.tr(
                        namedArgs: {
                          'languages': '${included.length}',
                          'keys': '$totalKeys',
                        },
                      ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () =>
                        context.read<FileUploadBloc>().add(ScanProjectEvent()),
              icon: const LingoDeskIcon(
                HugeIcons.strokeRoundedFolderAdd,
                size: 17,
              ),
              label: Text(LocaleKeys.uploadAddFolder.tr()),
            ),
            TextButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () => context.read<FileUploadBloc>().add(PickFilesEvent()),
              icon: const LingoDeskIcon(
                HugeIcons.strokeRoundedFileUpload,
                size: 17,
              ),
              label: Text(LocaleKeys.uploadAddFiles.tr()),
            ),
            TextButton(
              onPressed: state.isBusy
                  ? null
                  : () =>
                        context.read<FileUploadBloc>().add(ResetImportEvent()),
              child: Text(
                LocaleKeys.uploadStartOver.tr(),
                style: TextStyle(color: tokens.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _coverageLabel(List<ScannedLanguageGroup> groups, int totalKeys) {
    final cells = totalKeys * groups.length;
    if (cells == 0) {
      return '—';
    }
    final filled = groups.fold<int>(
      0,
      (sum, group) => sum + group.filledKeyCount,
    );
    return '${(filled / cells * 100).round()}%';
  }
}

/// The logo the import will hang on the app it creates.
///
/// The badge is a live preview of what the apps list will show: the
/// picked image, or the initials of whatever is currently typed in the
/// name field beside it.
class _ProjectIconField extends StatelessWidget {
  const _ProjectIconField({required this.state, required this.nameController});

  final FileUploadReady state;

  /// Watched so the initials track the name as it is typed.
  final TextEditingController nameController;

  /// Matches the height of the large name field it sits next to.
  static const _size = 50.0;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final bloc = context.read<FileUploadBloc>();
    final hasIcon = state.iconImage != null;
    final busy = state.isBusy;

    return LingoDeskFieldScaffold(
      label: LocaleKeys.uploadLogo.tr(),
      child: Row(
        children: [
          Tooltip(
            message: hasIcon
                ? LocaleKeys.uploadReplaceLogo.tr()
                : LocaleKeys.uploadUploadLogo.tr(),
            child: InkWell(
              onTap: busy
                  ? null
                  : () => bloc.add(ProjectIconPickRequestedEvent()),
              borderRadius: BorderRadius.circular(LingoDeskTheme.radius),
              child: SizedBox.square(
                dimension: _size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: nameController,
                      builder: (context, value, _) {
                        final name = value.text.trim();
                        return AppAvatar(
                          name: name.isEmpty
                              ? LocaleKeys.appsNewApp.tr()
                              : name,
                          initials: appInitialsFor(value.text),
                          iconImage: state.iconImage,
                          size: _size,
                        );
                      },
                    ),
                    // Sits half off the badge so it reads as an action on
                    // the logo rather than part of the artwork.
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tokens.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: tokens.border),
                        ),
                        child: state.isPickingIcon
                            ? const SizedBox.square(
                                dimension: 11,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                ),
                              )
                            : LingoDeskIcon(
                                HugeIcons.strokeRoundedImageAdd01,
                                size: 12,
                                color: tokens.muted,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasIcon) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: busy
                  ? null
                  : () => bloc.add(ProjectIconClearedEvent()),
              tooltip: LocaleKeys.uploadRemoveLogo.tr(),
              visualDensity: VisualDensity.compact,
              icon: const LingoDeskIcon(
                HugeIcons.strokeRoundedDelete02,
                size: 17,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
      ],
    );
  }
}

/// Files the scan found but could not use, folded away by default.
class _SkippedFiles extends StatelessWidget {
  const _SkippedFiles({required this.skipped});

  final List<SkippedScanFile> skipped;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return WorkspaceSurface(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(
            '${skipped.length} file(s) skipped',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: tokens.muted),
          ),
          children: [
            for (final file in skipped)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.relativePath,
                      style: LingoDeskTheme.codeStyle.copyWith(
                        color: tokens.foreground,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.reason,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Files staged: coverage first, then the list of what will be imported.
class _StagedState extends StatelessWidget {
  const _StagedState({required this.state});

  final FileUploadReady state;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkspaceSurface(child: _LanguageChecklist(state: state)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                LocaleKeys.uploadStagedFiles.tr(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            OutlinedButton.icon(
              onPressed: state.isBusy
                  ? null
                  : () => context.read<FileUploadBloc>().add(PickFilesEvent()),
              icon: const LingoDeskIcon(
                HugeIcons.strokeRoundedFolderAdd,
                size: 17,
              ),
              label: Text(LocaleKeys.uploadAddMore.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < state.stagedFiles.length; index++) ...[
          FadeSlideIn.staggered(
            index: index,
            child: StagedFileTile(
              file: state.stagedFiles[index],
              onRemove: () => context.read<FileUploadBloc>().add(
                RemoveFileEvent(state.stagedFiles[index].fileName),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 6),
          _ErrorRow(message: state.errorMessage!),
        ],
        const SizedBox(height: 4),
        Text(
          state.canImport
              ? LocaleKeys.uploadFilesReady.plural(state.validFiles.length)
              : LocaleKeys.uploadNeedValidFile.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
      ],
    );
  }
}

/// The naming contract, as a checklist that fills in as files are staged.
class _LanguageChecklist extends StatelessWidget {
  const _LanguageChecklist({required this.state, this.centered = false});

  final FileUploadReady state;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final tokens = LingoDeskTokens.of(context);
    final app = state.app!;
    final covered = state.coveredLanguages;
    final total = app.allLanguages.length;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Text(
              LocaleKeys.uploadRequiredLanguages.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(width: 10),
            Text(
              '${covered.length}/$total',
              style: LingoDeskTheme.codeStyle.copyWith(
                color: covered.length == total
                    ? LingoDeskColors.complete
                    : tokens.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          LocaleKeys.uploadNamingRule.tr(),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          children: [
            for (final language in app.allLanguages)
              _LanguageChip(
                language: language,
                isSource: language == app.sourceLanguage,
                isCovered: covered.contains(language),
              ),
          ],
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LingoDeskIcon(
          HugeIcons.strokeRoundedAlertCircle,
          size: 18,
          color: LingoDeskColors.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: LingoDeskColors.error),
          ),
        ),
      ],
    );
  }
}

/// One expected file: the literal name to give it, ticked once staged.
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
    final accent = isCovered ? LingoDeskColors.complete : tokens.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isCovered ? accent.withAlpha(20) : tokens.active,
        borderRadius: BorderRadius.circular(LingoDeskTheme.radiusSm),
        border: Border.all(
          color: isCovered ? accent.withAlpha(90) : tokens.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LingoDeskIcon(
            isCovered
                ? HugeIcons.strokeRoundedCheckmarkCircle02
                : HugeIcons.strokeRoundedCircle,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 8),
          Text(
            '$language.json',
            style: LingoDeskTheme.codeStyle.copyWith(
              color: isCovered ? accent : tokens.foreground,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isSource
                ? LocaleKeys.uploadLanguageSource.tr(
                    namedArgs: {
                      'language': SupportedLanguages.nameOf(language),
                    },
                  )
                : SupportedLanguages.nameOf(language),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
