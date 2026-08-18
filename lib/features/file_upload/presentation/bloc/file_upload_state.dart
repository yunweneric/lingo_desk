import '../../../app_management/domain/entities/app.dart';
import '../../domain/entities/scanned_project.dart';
import '../../domain/entities/uploaded_translation_file.dart';
import '../../domain/project_source.dart';

abstract class FileUploadState {}

class FileUploadInitial extends FileUploadState {}

class FileUploadReady extends FileUploadState {
  FileUploadReady({
    this.app,
    this.stagedFiles = const [],
    this.project,
    this.projectName,
    this.iconImage,
    this.selectedSource,
    this.excludedLanguages = const {},
    this.scannedSource,
    this.isScanning = false,
    this.isImporting = false,
    this.isPickingIcon = false,
    this.errorMessage,
  });

  /// The app being imported into, or null in project mode where the
  /// import creates one from the scanned folder.
  final App? app;

  /// Files picked so far, valid or not (app mode).
  final List<UploadedTranslationFile> stagedFiles;

  /// Everything gathered so far from folder scans and picked files
  /// (project mode).
  final ScannedProject? project;

  /// Name of the app the import will create; seeded from the scanned
  /// folder and editable.
  final String? projectName;

  /// Base64 PNG picked for the app the import will create, or null to
  /// fall back to the name's initials (project mode).
  final String? iconImage;

  /// Language chosen as the app's source (project mode).
  final String? selectedSource;

  /// Scanned languages the user unchecked.
  final Set<String> excludedLanguages;

  /// Folder the last scan came from and where each language sat in it.
  ///
  /// Recorded in both modes so the app the import lands on can export
  /// straight back to the codebase. Null until a folder is scanned.
  final ProjectSource? scannedSource;

  final bool isScanning;
  final bool isImporting;
  final bool isPickingIcon;

  /// Transient failure message (picker or import errors).
  final String? errorMessage;

  /// True when no app was supplied, so importing creates one.
  bool get isProjectMode => app == null;

  bool get isBusy => isScanning || isImporting || isPickingIcon;

  List<UploadedTranslationFile> get validFiles =>
      stagedFiles.where((file) => file.isValid).toList();

  /// Scanned languages kept for the import, source first.
  List<ScannedLanguageGroup> get includedGroups {
    final groups = <ScannedLanguageGroup>[
      ...?project?.groups.where(
        (group) => !excludedLanguages.contains(group.languageCode),
      ),
    ];
    groups.sort((a, b) {
      if (a.languageCode == selectedSource) {
        return -1;
      }
      if (b.languageCode == selectedSource) {
        return 1;
      }
      return a.languageCode.compareTo(b.languageCode);
    });
    return groups;
  }

  bool get canImport {
    if (isBusy) {
      return false;
    }
    if (!isProjectMode) {
      return validFiles.isNotEmpty;
    }
    return includedGroups.isNotEmpty && (projectName ?? '').trim().isNotEmpty;
  }

  /// True once something has been added to the project-mode preview.
  bool get hasProject => (project?.groups.isNotEmpty ?? false);

  /// Language codes covered by valid staged files (app mode).
  Set<String> get coveredLanguages =>
      validFiles.map((file) => file.languageCode).toSet();

  FileUploadReady copyWith({
    App? app,
    List<UploadedTranslationFile>? stagedFiles,
    ScannedProject? project,
    String? projectName,
    String? iconImage,
    String? selectedSource,
    Set<String>? excludedLanguages,
    ProjectSource? scannedSource,
    bool? isScanning,
    bool? isImporting,
    bool? isPickingIcon,
    String? errorMessage,
    bool clearError = false,
    bool clearIcon = false,
    bool reset = false,
  }) {
    return FileUploadReady(
      app: app ?? this.app,
      stagedFiles: stagedFiles ?? this.stagedFiles,
      project: reset ? null : (project ?? this.project),
      projectName: reset ? null : (projectName ?? this.projectName),
      iconImage: reset || clearIcon ? null : (iconImage ?? this.iconImage),
      selectedSource: reset ? null : (selectedSource ?? this.selectedSource),
      excludedLanguages:
          reset ? const {} : (excludedLanguages ?? this.excludedLanguages),
      scannedSource: reset ? null : (scannedSource ?? this.scannedSource),
      isScanning: isScanning ?? this.isScanning,
      isImporting: isImporting ?? this.isImporting,
      isPickingIcon: isPickingIcon ?? this.isPickingIcon,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Import finished; the caller can navigate to the editor.
class FileUploadImportSuccess extends FileUploadState {
  FileUploadImportSuccess(this.app);

  final App app;
}
