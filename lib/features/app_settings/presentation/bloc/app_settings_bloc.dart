import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/languages.dart';
import '../../../app_management/domain/entities/app.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../app_management/domain/usecases/create_app.dart';
import '../../../app_management/domain/usecases/pick_app_icon.dart';
import '../../../app_management/domain/usecases/update_app.dart';
import 'app_settings_event.dart';
import 'app_settings_state.dart';

class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState> {
  AppSettingsBloc({
    required this.createApp,
    required this.updateApp,
    required this.pickAppIcon,
  }) : super(AppSettingsInitial()) {
    on<InitializeAppSettingsEvent>(_onInitialize);
    on<SourceLanguageChangedEvent>(_onSourceLanguageChanged);
    on<TargetLanguageToggledEvent>(_onTargetLanguageToggled);
    on<AllTargetLanguagesToggledEvent>(_onAllTargetLanguagesToggled);
    on<AppIconPickRequestedEvent>(_onPickIcon);
    on<AppIconClearedEvent>(_onClearIcon);
    on<SaveAppSettingsEvent>(_onSave);
  }

  final CreateApp createApp;
  final UpdateApp updateApp;
  final PickAppIcon pickAppIcon;

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
        iconImage: app?.iconImage,
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

  Future<void> _onPickIcon(
    AppIconPickRequestedEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    final current = state;
    if (current is! AppSettingsReady || current.isPickingIcon) {
      return;
    }

    emit(current.copyWith(isPickingIcon: true, clearError: true));
    final result = await pickAppIcon(const NoParams());

    final settled = state;
    if (settled is! AppSettingsReady) {
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

  void _onClearIcon(AppIconClearedEvent event, Emitter<AppSettingsState> emit) {
    final current = state;
    if (current is! AppSettingsReady) {
      return;
    }
    emit(current.copyWith(clearIcon: true, clearError: true));
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
                iconImage: current.iconImage,
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
                  iconImage: current.iconImage,
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
