import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../translation_editor/domain/usecases/save_translations.dart';
import '../../domain/entities/uploaded_translation_file.dart';
import '../../domain/usecases/parse_translation_file.dart';
import '../../domain/usecases/pick_translation_files.dart';
import 'file_upload_event.dart';
import 'file_upload_state.dart';

class FileUploadBloc extends Bloc<FileUploadEvent, FileUploadState> {
  FileUploadBloc({
    required this.pickTranslationFiles,
    required this.parseTranslationFile,
    required this.saveTranslations,
  }) : super(FileUploadInitial()) {
    on<LoadUploadContextEvent>(_onLoadUploadContext);
    on<PickFilesEvent>(_onPickFiles);
    on<RemoveFileEvent>(_onRemoveFile);
    on<ConfirmImportEvent>(_onConfirmImport);
  }

  final PickTranslationFiles pickTranslationFiles;
  final ParseTranslationFile parseTranslationFile;
  final SaveTranslations saveTranslations;

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
    if (current is! FileUploadReady || current.isImporting) {
      return;
    }

    final pickResult = await pickTranslationFiles(const NoParams());
    await pickResult.fold(
      (failure) async => emit(current.copyWith(errorMessage: failure.message)),
      (pickedFiles) async {
        if (pickedFiles.isEmpty) {
          return; // Picker canceled.
        }

        final staged = [...current.stagedFiles];
        final expectedLanguages = current.app.allLanguages;

        for (final picked in pickedFiles) {
          final language = picked.inferredLanguage;
          UploadedTranslationFile stagedFile;

          if (!expectedLanguages.contains(language)) {
            stagedFile = UploadedTranslationFile(
              fileName: picked.fileName,
              languageCode: language,
              error:
                  '"$language" is not a language of this app '
                  '(expected: ${expectedLanguages.join(', ')}).',
            );
          } else {
            final parseResult = await parseTranslationFile(
              ParseTranslationFileParams(content: picked.content),
            );
            stagedFile = parseResult.fold(
              (failure) => UploadedTranslationFile(
                fileName: picked.fileName,
                languageCode: language,
                error: failure.message,
              ),
              (flat) => UploadedTranslationFile(
                fileName: picked.fileName,
                languageCode: language,
                translations: flat,
              ),
            );
          }

          // A newly picked file replaces a previously staged one for the
          // same language (or with the same name).
          staged.removeWhere(
            (file) =>
                file.fileName == stagedFile.fileName ||
                (stagedFile.isValid &&
                    file.isValid &&
                    file.languageCode == stagedFile.languageCode),
          );
          staged.add(stagedFile);
        }

        emit(current.copyWith(stagedFiles: staged, clearError: true));
      },
    );
  }

  void _onRemoveFile(RemoveFileEvent event, Emitter<FileUploadState> emit) {
    final current = state;
    if (current is! FileUploadReady) {
      return;
    }
    emit(
      current.copyWith(
        stagedFiles:
            current.stagedFiles
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

    final filesByLanguage = <String, Map<String, String>>{
      for (final file in current.validFiles)
        file.languageCode: file.translations,
    };

    final result = await saveTranslations(
      SaveTranslationsParams(
        appId: current.app.id,
        filesByLanguage: filesByLanguage,
      ),
    );

    result.fold(
      (failure) => emit(
        current.copyWith(isImporting: false, errorMessage: failure.message),
      ),
      (_) => emit(FileUploadImportSuccess(current.app)),
    );
  }
}
