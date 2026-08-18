import '../../../app_management/domain/entities/app.dart';

abstract class FileUploadEvent {}

/// Initializes the upload screen.
///
/// [app] is null in project mode, where the import creates the app.
class LoadUploadContextEvent extends FileUploadEvent {
  LoadUploadContextEvent(this.app);

  final App? app;
}

/// Opens the platform file picker and adds the selected files.
class PickFilesEvent extends FileUploadEvent {}

/// Opens the folder picker and scans it for translation files.
class ScanProjectEvent extends FileUploadEvent {}

/// Renames the app the import will create (project mode).
class ProjectNameChangedEvent extends FileUploadEvent {
  ProjectNameChangedEvent(this.name);

  final String name;
}

/// Opens the image picker for the app icon (project mode).
class ProjectIconPickRequestedEvent extends FileUploadEvent {}

/// Drops the picked icon, falling back to the name's initials.
class ProjectIconClearedEvent extends FileUploadEvent {}

/// Drops everything added so far and starts the import over.
class ResetImportEvent extends FileUploadEvent {}

/// Picks which scanned language is the app's source (project mode).
class SourceLanguageSelectedEvent extends FileUploadEvent {
  SourceLanguageSelectedEvent(this.languageCode);

  final String languageCode;
}

/// Includes or excludes a scanned language from the import.
class ToggleScannedLanguageEvent extends FileUploadEvent {
  ToggleScannedLanguageEvent(this.languageCode);

  final String languageCode;
}

/// Removes a staged file.
class RemoveFileEvent extends FileUploadEvent {
  RemoveFileEvent(this.fileName);

  final String fileName;
}

/// Imports everything staged: into the app in app mode, into a newly
/// created app in project mode.
class ConfirmImportEvent extends FileUploadEvent {}
