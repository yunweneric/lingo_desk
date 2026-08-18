import 'package:flutter_bloc/flutter_bloc.dart';

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
    on<SaveAppSettingsEvent>(_onSave);
  }

  final CreateApp createApp;
  final UpdateApp updateApp;

  void _onInitialize(
    InitializeAppSettingsEvent event,
    Emitter<AppSettingsState> emit,
  ) {
    final app = event.app;
    emit(
      AppSettingsReady(
        editingApp: app,
        sourceLanguage: app?.sourceLanguage ?? 'en',
        targetLanguages: List.of(app?.targetLanguages ?? const []),
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
