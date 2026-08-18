import '../../../app_management/domain/entities/app.dart';

abstract class AppSettingsState {}

class AppSettingsInitial extends AppSettingsState {}

class AppSettingsReady extends AppSettingsState {
  AppSettingsReady({
    this.editingApp,
    required this.sourceLanguage,
    required this.targetLanguages,
    this.isSaving = false,
    this.errorMessage,
  });

  /// The app being edited, or null when creating a new one.
  final App? editingApp;

  final String sourceLanguage;
  final List<String> targetLanguages;
  final bool isSaving;
  final String? errorMessage;

  bool get isCreateMode => editingApp == null;

  AppSettingsReady copyWith({
    String? sourceLanguage,
    List<String>? targetLanguages,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppSettingsReady(
      editingApp: editingApp,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// The app was saved; [wasCreate] tells the caller which flow to follow.
class AppSettingsSaveSuccess extends AppSettingsState {
  AppSettingsSaveSuccess({required this.app, required this.wasCreate});

  final App app;
  final bool wasCreate;
}
