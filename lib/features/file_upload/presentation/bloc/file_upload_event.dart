import '../../../app_management/domain/entities/app.dart';

abstract class FileUploadEvent {}

/// Initializes the upload screen for an app.
class LoadUploadContextEvent extends FileUploadEvent {
  LoadUploadContextEvent(this.app);

  final App app;
}

/// Opens the platform file picker and stages the selected files.
class PickFilesEvent extends FileUploadEvent {}

/// Removes a staged file.
class RemoveFileEvent extends FileUploadEvent {
  RemoveFileEvent(this.fileName);

  final String fileName;
}

/// Imports all valid staged files into the app's workspace.
class ConfirmImportEvent extends FileUploadEvent {}
