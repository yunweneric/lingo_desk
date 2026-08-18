import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/languages.dart';
import '../../../app_management/domain/entities/app.dart';
import '../../../app_management/domain/usecases/create_app.dart';
import '../../../app_management/domain/usecases/update_app.dart';
import 'app_settings_event.dart';
import 'app_settings_state.dart';

class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState> {
  AppSettingsBloc({required this.createApp, required this.updateApp})
    : super(AppSettingsInitial()) {
    on<InitializeAppSettingsEvent>(_onInitialize);
    on<SourceLanguageChangedEvent>(_onSourceLanguageChanged);
    on<TargetLanguageToggledEvent>(_onTargetLanguageToggled);
    on<AllTargetLanguagesToggledEvent>(_onAllTargetLanguagesToggled);
    on<SaveAppSettingsEvent>(_onSave);
  }

  final CreateApp createApp;
  final UpdateApp updateApp;

  void _onInitialize(
    InitializeAppSettingsEvent event,
    Emitter<AppSettingsState> emit,
  ) {
    final app = event.app;
    final source = app?.sourceLanguage ?? 'en';
    // Creating: start from the workspace defaults, minus the source.
    final targets =
        app?.targetLanguages ??
        (event.defaultTargetLanguages ?? const <String>[])
            .where((language) => language != source)
            .toList();
    emit(
      AppSettingsReady(
        editingApp: app,
        sourceLanguage: source,
        targetLanguages: List.of(targets),
      ),
    );
  }

  void _onSourceLanguageChanged(
    SourceLanguageChangedEvent event,
    Emitter<AppSettingsState> emit,
  ) {
    final current = state;
    if (current is! AppSettingsReady) {
      return;
    }
    emit(
      current.copyWith(
        sourceLanguage: event.languageCode,
        // The source language cannot also be a target.
        targetLanguages:
            current.targetLanguages
                .where((language) => language != event.languageCode)
                .toList(),
        clearError: true,
      ),
    );
  }

  void _onTargetLanguageToggled(
    TargetLanguageToggledEvent event,
    Emitter<AppSettingsState> emit,
  ) {
    final current = state;
    if (current is! AppSettingsReady) {
      return;
    }
    final targets = List.of(current.targetLanguages);
    if (targets.contains(event.languageCode)) {
      targets.remove(event.languageCode);
    } else if (event.languageCode != current.sourceLanguage) {
      targets.add(event.languageCode);
    }
    emit(current.copyWith(targetLanguages: targets, clearError: true));
  }

  void _onAllTargetLanguagesToggled(
    AllTargetLanguagesToggledEvent event,
    Emitter<AppSettingsState> emit,
  ) {
    final current = state;
    if (current is! AppSettingsReady) {
      return;
    }
    emit(
      current.copyWith(
        targetLanguages:
            event.selectAll
                ? [
                  for (final option in SupportedLanguages.all)
                    if (option.code != current.sourceLanguage) option.code,
                ]
                : const <String>[],
        clearError: true,
      ),
    );
  }

  Future<void> _onSave(
    SaveAppSettingsEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    final current = state;
    if (current is! AppSettingsReady || current.isSaving) {
      return;
    }

    emit(current.copyWith(isSaving: true, clearError: true));

    final editingApp = current.editingApp;
    final result =
        editingApp == null
            ? await createApp(
              CreateAppParams(
                name: event.name,
                sourceLanguage: current.sourceLanguage,
                targetLanguages: current.targetLanguages,
              ),
            )
            : await updateApp(
              UpdateAppParams(
                app: App(
                  id: editingApp.id,
                  name: event.name,
                  sourceLanguage: current.sourceLanguage,
                  targetLanguages: current.targetLanguages,
                  createdAt: editingApp.createdAt,
                  updatedAt: editingApp.updatedAt,
                ),
              ),
            );

    result.fold(
      (failure) => emit(
        current.copyWith(isSaving: false, errorMessage: failure.message),
      ),
      (app) =>
          emit(AppSettingsSaveSuccess(app: app, wasCreate: editingApp == null)),
    );
  }
}
