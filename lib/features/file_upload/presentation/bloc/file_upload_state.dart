import '../../../app_management/domain/entities/app.dart';
import '../../domain/entities/uploaded_translation_file.dart';

abstract class FileUploadState {}

class FileUploadInitial extends FileUploadState {}

class FileUploadReady extends FileUploadState {
  FileUploadReady({
    required this.app,
    this.stagedFiles = const [],
    this.isImporting = false,
    this.errorMessage,
  });

  final App app;

  /// Files picked so far, valid or not.
  final List<UploadedTranslationFile> stagedFiles;

  final bool isImporting;

  /// Transient failure message (picker or import errors).
  final String? errorMessage;

  List<UploadedTranslationFile> get validFiles =>
      stagedFiles.where((file) => file.isValid).toList();

  bool get canImport => validFiles.isNotEmpty && !isImporting;

  /// Language codes covered by valid staged files.
  Set<String> get coveredLanguages =>
      validFiles.map((file) => file.languageCode).toSet();

  FileUploadReady copyWith({
    App? app,
    List<UploadedTranslationFile>? stagedFiles,
    bool? isImporting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FileUploadReady(
      app: app ?? this.app,
      stagedFiles: stagedFiles ?? this.stagedFiles,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Import finished; the caller can navigate to the editor.
class FileUploadImportSuccess extends FileUploadState {
  FileUploadImportSuccess(this.app);

  final App app;
}
