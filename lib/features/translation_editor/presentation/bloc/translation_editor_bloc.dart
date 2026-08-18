import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app_management/domain/usecases/get_app_by_id.dart';
import '../../domain/usecases/add_translation_key.dart';
import '../../domain/usecases/delete_translation_key.dart';
import '../../domain/usecases/export_translations.dart';
import '../../domain/usecases/get_translations.dart';
import '../../domain/usecases/update_translation.dart';
import 'translation_editor_event.dart';
import 'translation_editor_state.dart';

class TranslationEditorBloc
    extends Bloc<TranslationEditorEvent, TranslationEditorState> {
  TranslationEditorBloc({
    required this.getAppById,
    required this.getTranslations,
    required this.updateTranslation,
    required this.addTranslationKey,
    required this.deleteTranslationKey,
    required this.exportTranslations,
  }) : super(TranslationEditorInitial()) {
    on<LoadEditorEvent>(_onLoadEditor);
    on<UpdateCellEvent>(_onUpdateCell);
    on<AddKeyEvent>(_onAddKey);
    on<DeleteKeyEvent>(_onDeleteKey);
    on<ToggleMissingOnlyEvent>(_onToggleMissingOnly);
    on<SearchKeysEvent>(_onSearchKeys);
    on<ExportTranslationsEvent>(_onExportTranslations);
  }

  final GetAppById getAppById;
  final GetTranslations getTranslations;
  final UpdateTranslation updateTranslation;
  final AddTranslationKey addTranslationKey;
  final DeleteTranslationKey deleteTranslationKey;
  final ExportTranslations exportTranslations;

  String? _appId;

  Future<void> _onLoadEditor(
    LoadEditorEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    _appId = event.appId;
    final previous = state;
    if (previous is! TranslationEditorLoaded) {
      emit(TranslationEditorLoading());
    }

    final appResult = await getAppById(GetAppByIdParams(id: event.appId));
    await appResult.fold(
      (failure) async => emit(TranslationEditorError(failure.message)),
      (app) async {
        final translationsResult = await getTranslations(
          GetTranslationsParams(appId: event.appId),
        );
        translationsResult.fold(
          (failure) => emit(TranslationEditorError(failure.message)),
          (entries) {
            emit(
              TranslationEditorLoaded(
                app: app,
                entries: entries,
                showMissingOnly:
                    previous is TranslationEditorLoaded
                        ? previous.showMissingOnly
                        : false,
                query:
                    previous is TranslationEditorLoaded ? previous.query : '',
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onUpdateCell(
    UpdateCellEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }

    // Optimistic update so typing feels instant.
    final updatedEntries = [
      for (final entry in current.entries)
        if (entry.key == event.key)
          entry.copyWithValue(event.language, event.value)
        else
          entry,
    ];
    emit(current.copyWith(entries: updatedEntries, clearNotice: true));

    final result = await updateTranslation(
      UpdateTranslationParams(
        appId: appId,
        key: event.key,
        language: event.language,
        value: event.value,
      ),
    );
    result.fold((failure) {
      final latest = state;
      if (latest is TranslationEditorLoaded) {
        emit(
          latest.copyWith(notice: EditorNotice(failure.message, isError: true)),
        );
      }
      add(LoadEditorEvent(appId));
    }, (_) {});
  }

  Future<void> _onAddKey(
    AddKeyEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }

    final result = await addTranslationKey(
      AddTranslationKeyParams(
        appId: appId,
        key: event.key,
        values: event.values,
      ),
    );

    await result.fold(
      (failure) async => emit(
        current.copyWith(notice: EditorNotice(failure.message, isError: true)),
      ),
      (_) async {
        await _reloadEntries(
          emit,
          appId,
          notice: EditorNotice('Added key "${event.key.trim()}".'),
        );
      },
    );
  }

  Future<void> _onDeleteKey(
    DeleteKeyEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }

    final result = await deleteTranslationKey(
      DeleteTranslationKeyParams(appId: appId, key: event.key),
    );

    await result.fold(
      (failure) async => emit(
        current.copyWith(notice: EditorNotice(failure.message, isError: true)),
      ),
      (_) async {
        await _reloadEntries(
          emit,
          appId,
          notice: EditorNotice('Deleted key "${event.key}".'),
        );
      },
    );
  }

  void _onToggleMissingOnly(
    ToggleMissingOnlyEvent event,
    Emitter<TranslationEditorState> emit,
  ) {
    final current = state;
    if (current is TranslationEditorLoaded) {
      emit(
        current.copyWith(
          showMissingOnly: !current.showMissingOnly,
          clearNotice: true,
        ),
      );
    }
  }

  void _onSearchKeys(
    SearchKeysEvent event,
    Emitter<TranslationEditorState> emit,
  ) {
    final current = state;
    if (current is TranslationEditorLoaded) {
      emit(current.copyWith(query: event.query, clearNotice: true));
    }
  }

  Future<void> _onExportTranslations(
    ExportTranslationsEvent event,
    Emitter<TranslationEditorState> emit,
  ) async {
    final current = state;
    final appId = _appId;
    if (current is! TranslationEditorLoaded || appId == null) {
      return;
    }

    final archiveName = archiveNameFor(current.app.name);
    final result = await exportTranslations(
      ExportTranslationsParams(
        appId: appId,
        languages: event.languages,
        archiveName: archiveName,
      ),
    );

    result.fold(
      (failure) => emit(
        current.copyWith(notice: EditorNotice(failure.message, isError: true)),
      ),
      (savedCount) {
        final message =
            savedCount == 0
                ? 'Export canceled.'
                : savedCount == 1
                ? 'Exported 1 file as $archiveName.'
                : 'Exported $savedCount files as $archiveName.';
        emit(current.copyWith(notice: EditorNotice(message)));
      },
    );
  }

  Future<void> _reloadEntries(
    Emitter<TranslationEditorState> emit,
    String appId, {
    EditorNotice? notice,
  }) async {
    final result = await getTranslations(GetTranslationsParams(appId: appId));
    result.fold((failure) => emit(TranslationEditorError(failure.message)), (
      entries,
    ) {
      final latest = state;
      if (latest is TranslationEditorLoaded) {
        emit(latest.copyWith(entries: entries, notice: notice));
      }
    });
  }
}
