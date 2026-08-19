import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/preferences/app_settings_controller.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../app_management/domain/entities/app.dart';
import '../../../app_management/domain/usecases/create_app.dart';
import '../../../app_management/domain/usecases/pick_app_icon.dart';
import '../../../app_management/domain/usecases/update_app.dart';
import '../../../translation_editor/domain/usecases/save_translations.dart';
import '../../domain/entities/scanned_project.dart';
import '../../domain/entities/uploaded_translation_file.dart';
import '../../domain/project_source.dart';
import '../../domain/usecases/parse_translation_file.dart';
import '../../domain/usecases/pick_translation_files.dart';
import '../../domain/usecases/scan_project_folder.dart';
import '../../domain/translation_grouping.dart';
import 'file_upload_event.dart';
import 'file_upload_state.dart';
import '../../../../core/localization/export.dart';

class FileUploadBloc extends Bloc<FileUploadEvent, FileUploadState> {
  FileUploadBloc({
    required this.pickTranslationFiles,
    required this.parseTranslationFile,
    required this.scanProjectFolder,
    required this.saveTranslations,
    required this.createApp,
    required this.updateApp,
    required this.pickAppIcon,
    required this.settings,
  }) : super(FileUploadInitial()) {
    on<LoadUploadContextEvent>(_onLoadUploadContext);
    on<PickFilesEvent>(_onPickFiles);
    on<ScanProjectEvent>(_onScanProject);
    on<ProjectNameChangedEvent>(_onProjectNameChanged);
    on<ProjectIconPickRequestedEvent>(_onPickProjectIcon);
    on<ProjectIconClearedEvent>(_onClearProjectIcon);
    on<ResetImportEvent>(_onResetImport);
    on<SourceLanguageSelectedEvent>(_onSourceLanguageSelected);
    on<ToggleScannedLanguageEvent>(_onToggleScannedLanguage);
    on<RemoveFileEvent>(_onRemoveFile);
    on<ConfirmImportEvent>(_onConfirmImport);
  }

  final PickTranslationFiles pickTranslationFiles;
  final ParseTranslationFile parseTranslationFile;
  final ScanProjectFolder scanProjectFolder;
  final SaveTranslations saveTranslations;
  final CreateApp createApp;
  final UpdateApp updateApp;
  final PickAppIcon pickAppIcon;
  final AppSettingsController settings;

  void _onLoadUploadContext(
    LoadUploadContextEvent event,
    Emitter<FileUploadState> emit,
  ) {
    emit(FileUploadReady(app: event.app));
  }

  Future<void> _onPickFiles(
    PickFilesEvent event,
    Emitter<FileUploadState> emit,
  ) async {
    final current = state;
    if (current is! FileUploadReady || current.isBusy) {
      return;
    }

    final pickResult = await pickTranslationFiles(const NoParams());
    await pickResult.fold(
      (failure) async => emit(current.copyWith(errorMessage: failure.message)),
      (pickedFiles) async {
        if (pickedFiles.isEmpty) {
          return; // Picker canceled.
        }

        if (current.isProjectMode) {
          // Hand-picked files feed the same preview a folder scan does.
          final grouper = TranslationGrouper(parseTranslationFile);
          grouper.seed(current.project?.groups ?? const []);
          for (final picked in pickedFiles) {
            await grouper.add(
              GroupingCandidate(
                displayPath: picked.fileName,
                fileName: picked.fileName,
                content: picked.content,
              ),
            );
          }
          emit(_withProject(current, _merged(current, grouper)));
          return;
        }

        var staged = [...current.stagedFiles];
        for (final picked in pickedFiles) {
          staged = _stage(
            staged,
            await _validate(
              fileName: picked.fileName,
              language: picked.inferredLanguage,
              content: picked.content,
              app: current.app,
            ),
          );
        }

        emit(current.copyWith(stagedFiles: staged, clearError: true));
      },
    );
  }

  /// Folds a fresh batch into the project preview, keeping the skipped
  /// files already on show.
  ScannedProject _merged(FileUploadReady current, TranslationGrouper grouper) {
    final previous = current.project;
    return ScannedProject(
      rootPath: previous?.rootPath ?? '',
      projectName:
          previous?.projectName ?? LocaleKeys.uploadDefaultProjectName.tr(),
      groups: grouper.groups,
      skipped: [
        ...?previous?.skipped.where(
          (file) => !grouper.skipped.any(
            (fresh) => fresh.relativePath == file.relativePath,
          ),
        ),
        ...grouper.skipped,
      ],
    );
  }

  /// Emits a project preview, seeding the name and source the first time
  /// something lands in it.
  FileUploadReady _withProject(
    FileUploadReady current,
    ScannedProject project,
  ) {
    return current.copyWith(
      isScanning: false,
      project: project,
      projectName: current.projectName ?? project.projectName,
      selectedSource: project.languages.contains(current.selectedSource)
          ? current.selectedSource
          : project.suggestedSource,
      clearError: true,
    );
  }

  Future<void> _onScanProject(
    ScanProjectEvent event,
    Emitter<FileUploadState> emit,
  ) async {
    final current = state;
    if (current is! FileUploadReady || current.isBusy) {
      return;
    }

    emit(current.copyWith(isScanning: true, clearError: true));

    final result = await scanProjectFolder(
      ScanProjectFolderParams(
        existing: current.isProjectMode ? current.project?.groups : null,
      ),
    );
    final scanning = state;
    if (scanning is! FileUploadReady) {
      return;
    }

    result.fold(
      (failure) => emit(
        scanning.copyWith(isScanning: false, errorMessage: failure.message),
      ),
      (project) {
        if (project == null) {
          emit(scanning.copyWith(isScanning: false)); // Picker canceled.
          return;
        }
        if (project.isEmpty) {
          emit(
            scanning.copyWith(
              isScanning: false,
              errorMessage: LocaleKeys.uploadNoFilesFound.tr(
                namedArgs: {'name': project.projectName},
              ),
            ),
          );
          return;
        }

        // Both modes remember where the files came from, so the app the
        // import lands on can export straight back into the codebase.
        final source = _mergedSource(scanning.scannedSource, project);

        if (scanning.isProjectMode) {
          emit(_withProject(scanning, project).copyWith(scannedSource: source));
        } else {
          // App mode: the scan just feeds the staging list, and the
          // app's own languages still decide what is accepted.
          emit(
            scanning.copyWith(
              isScanning: false,
              stagedFiles: _stageScannedGroups(scanning, project),
              scannedSource: source,
              clearError: true,
            ),
          );
        }
      },
    );
  }

  /// Folds a fresh scan into the project reference kept so far.
  ///
  /// The first folder scanned stays the reference: a second folder
  /// somewhere else cannot be written back to through the first one's
  /// root, so its layout is dropped rather than mixed in.
  ProjectSource? _mergedSource(
    ProjectSource? existing,
    ScannedProject project,
  ) {
    final fresh = projectSourceFrom(project, project.groups);
    if (fresh == null) {
      return existing;
    }
    if (existing == null) {
      return fresh;
    }
    if (existing.rootPath != fresh.rootPath) {
      return existing;
    }
    return ProjectSource(
      rootPath: existing.rootPath,
      languageFiles: {...existing.languageFiles, ...fresh.languageFiles},
    );
  }

  void _onSourceLanguageSelected(
    SourceLanguageSelectedEvent event,
    Emitter<FileUploadState> emit,
  ) {
    final current = state;
    if (current is! FileUploadReady || current.isBusy) {
      return;
    }
    emit(
      current.copyWith(
        selectedSource: event.languageCode,
        // The source is always imported.
        excludedLanguages: {...current.excludedLanguages}
          ..remove(event.languageCode),
        clearError: true,
      ),
    );
  }

  void _onToggleScannedLanguage(
    ToggleScannedLanguageEvent event,
    Emitter<FileUploadState> emit,
  ) {
    final current = state;
    if (current is! FileUploadReady ||
        current.isBusy ||
        event.languageCode == current.selectedSource) {
      return;
    }

    final excluded = {...current.excludedLanguages};
    if (!excluded.remove(event.languageCode)) {
      excluded.add(event.languageCode);
    }
    emit(current.copyWith(excludedLanguages: excluded, clearError: true));
  }

  void _onProjectNameChanged(
    ProjectNameChangedEvent event,
    Emitter<FileUploadState> emit,
  ) {
    final current = state;
    if (current is! FileUploadReady || current.isBusy) {
      return;
    }
    emit(current.copyWith(projectName: event.name, clearError: true));
  }

  Future<void> _onPickProjectIcon(
    ProjectIconPickRequestedEvent event,
    Emitter<FileUploadState> emit,
  ) async {
    final current = state;
    if (current is! FileUploadReady || current.isBusy) {
      return;
    }

    emit(current.copyWith(isPickingIcon: true, clearError: true));
    final result = await pickAppIcon(const NoParams());

    // The picker is modal but a scan can still settle behind it, so the
    // icon lands on whatever state is current rather than the captured one.
    final settled = state;
    if (settled is! FileUploadReady) {
      return;
    }
    result.fold(
      (failure) => emit(
        settled.copyWith(isPickingIcon: false, errorMessage: failure.message),
      ),
      // A canceled picker leaves the current icon alone.
      (icon) => emit(
        icon == null
            ? settled.copyWith(isPickingIcon: false)
            : settled.copyWith(isPickingIcon: false, iconImage: icon),
      ),
    );
  }

  void _onClearProjectIcon(
    ProjectIconClearedEvent event,
    Emitter<FileUploadState> emit,
  ) {
    final current = state;
    if (current is! FileUploadReady || current.isBusy) {
      return;
    }
    emit(current.copyWith(clearIcon: true, clearError: true));
  }

  void _onResetImport(ResetImportEvent event, Emitter<FileUploadState> emit) {
    final current = state;
    if (current is! FileUploadReady || current.isBusy) {
      return;
    }
    emit(FileUploadReady(app: current.app));
  }

  void _onRemoveFile(RemoveFileEvent event, Emitter<FileUploadState> emit) {
    final current = state;
    if (current is! FileUploadReady) {
      return;
    }
    emit(
      current.copyWith(
        stagedFiles: current.stagedFiles
            .where((file) => file.fileName != event.fileName)
            .toList(),
        clearError: true,
      ),
    );
  }

  Future<void> _onConfirmImport(
    ConfirmImportEvent event,
    Emitter<FileUploadState> emit,
  ) async {
    final current = state;
    if (current is! FileUploadReady || !current.canImport) {
      return;
    }

    emit(current.copyWith(isImporting: true, clearError: true));

    final App app;
    final Map<String, Map<String, String>> filesByLanguage;

    if (current.isProjectMode) {
      final created = await _createProjectApp(current);
      final failure = created.fold((failure) => failure, (_) => null);
      if (failure != null) {
        emit(
          current.copyWith(isImporting: false, errorMessage: failure.message),
        );
        return;
      }
      app = created.getOrElse(() => throw StateError('App was not created.'));
      filesByLanguage = {
        for (final group in current.includedGroups)
          group.languageCode: group.translations,
      };
    } else {
      app = current.app!;
      filesByLanguage = {
        for (final file in current.validFiles)
          file.languageCode: file.translations,
      };
    }

    final result = await saveTranslations(
      SaveTranslationsParams(appId: app.id, filesByLanguage: filesByLanguage),
    );

    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) {
      emit(
        // In project mode the app already exists at this point; it stays
        // in the workspace so the import can be retried against it.
        current.copyWith(isImporting: false, errorMessage: failure.message),
      );
      return;
    }

    // Project mode already created the app with its origin attached; an
    // existing app picks it up here, so scanning a folder into an app
    // made by hand also earns it a save-back-to-project.
    emit(
      FileUploadImportSuccess(
        current.isProjectMode ? app : await _withSource(app, current),
      ),
    );
  }

  /// Attaches the scanned origin to an existing app.
  ///
  /// The app keeps whichever project it was already tied to — the point
  /// is to remember the *initial* one — and only gains paths for the
  /// languages it did not have yet. Returns the app unchanged when there
  /// is nothing to record or the update fails; a saved import is not
  /// worth failing over a bookkeeping write.
  Future<App> _withSource(App app, FileUploadReady state) async {
    final source = state.scannedSource;
    if (source == null) {
      return app;
    }

    final updated = App(
      id: app.id,
      name: app.name,
      sourceLanguage: app.sourceLanguage,
      targetLanguages: app.targetLanguages,
      createdAt: app.createdAt,
      updatedAt: app.updatedAt,
      iconImage: app.iconImage,
      projectPath: app.hasProject ? app.projectPath : source.rootPath,
      languageFiles: {...source.languageFiles, ...app.languageFiles},
    );

    final result = await updateApp(UpdateAppParams(app: updated));
    return result.getOrElse(() => app);
  }

  /// Creates the app the scanned project is imported into.
  ///
  /// Every scanned language but the source becomes a target. An app must
  /// have at least one target, so a single-language project falls back to
  /// the workspace defaults, and then to any other supported locale.
  Future<Either<Failure, App>> _createProjectApp(FileUploadReady state) {
    final source = state.selectedSource ?? state.project!.suggestedSource;
    var targets = _without(
      source,
      state.includedGroups.map((group) => group.languageCode),
    );

    if (targets.isEmpty) {
      targets = _without(source, settings.defaultTargetLanguages);
    }
    if (targets.isEmpty) {
      targets = _without(
        source,
        SupportedLanguages.all.map((option) => option.code),
      ).take(1).toList();
    }

    final projectSource = state.scannedSource;
    return createApp(
      CreateAppParams(
        name: (state.projectName ?? state.project!.projectName).trim(),
        sourceLanguage: source,
        targetLanguages: targets,
        iconImage: state.iconImage,
        projectPath: projectSource?.rootPath,
        // Every scanned language keeps its path, not just the imported
        // ones, so adding a target later already knows where it lives.
        languageFiles: projectSource?.languageFiles ?? const {},
      ),
    );
  }

  List<String> _without(String source, Iterable<String> languages) =>
      languages.where((language) => language != source).toList();

  /// Turns a scan into staged files for an existing app, so the app's
  /// language set still decides what is accepted.
  List<UploadedTranslationFile> _stageScannedGroups(
    FileUploadReady state,
    ScannedProject project,
  ) {
    var staged = [...state.stagedFiles];
    for (final group in project.groups) {
      staged = _stage(
        staged,
        _fileFor(
          fileName: group.relativePaths.join(', '),
          language: group.languageCode,
          translations: group.translations,
          app: state.app,
        ),
      );
    }
    return staged;
  }

  Future<UploadedTranslationFile> _validate({
    required String fileName,
    required String language,
    required String content,
    required App? app,
  }) async {
    if (app != null && !app.allLanguages.contains(language)) {
      return _fileFor(
        fileName: fileName,
        language: language,
        translations: const {},
        app: app,
      );
    }

    final parseResult = await parseTranslationFile(
      ParseTranslationFileParams(content: content),
    );
    return parseResult.fold(
      (failure) => UploadedTranslationFile(
        fileName: fileName,
        languageCode: language,
        error: failure.message,
      ),
      (flat) => UploadedTranslationFile(
        fileName: fileName,
        languageCode: language,
        translations: flat,
      ),
    );
  }

  UploadedTranslationFile _fileFor({
    required String fileName,
    required String language,
    required Map<String, String> translations,
    required App? app,
  }) {
    if (app != null && !app.allLanguages.contains(language)) {
      return UploadedTranslationFile(
        fileName: fileName,
        languageCode: language,
        error:
            '"$language" is not a language of this app '
            '(expected: ${app.allLanguages.join(', ')}).',
      );
    }
    return UploadedTranslationFile(
      fileName: fileName,
      languageCode: language,
      translations: translations,
    );
  }

  /// A newly staged file replaces a previously staged one for the same
  /// language (or with the same name).
  List<UploadedTranslationFile> _stage(
    List<UploadedTranslationFile> staged,
    UploadedTranslationFile file,
  ) {
    return [
      ...staged.where(
        (existing) =>
            existing.fileName != file.fileName &&
            !(file.isValid &&
                existing.isValid &&
                existing.languageCode == file.languageCode),
      ),
      file,
    ];
  }
}
