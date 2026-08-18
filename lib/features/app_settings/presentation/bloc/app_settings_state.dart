import '../../../app_management/domain/entities/app.dart';

abstract class AppSettingsState {}

class AppSettingsInitial extends AppSettingsState {}

class AppSettingsReady extends AppSettingsState {
  AppSettingsReady({
    this.editingApp,
    required this.sourceLanguage,
    required this.targetLanguages,
    this.iconImage,
    this.isSaving = false,
    this.isPickingIcon = false,
    this.errorMessage,
  });

  /// The app being edited, or null when creating a new one.
  final App? editingApp;

  final String sourceLanguage;
  final List<String> targetLanguages;

  /// Base64 PNG for the app's icon; null falls back to its initials.
  final String? iconImage;

  final bool isSaving;
  final bool isPickingIcon;
  final String? errorMessage;

  bool get isCreateMode => editingApp == null;

  AppSettingsReady copyWith({
    String? sourceLanguage,
    List<String>? targetLanguages,
    String? iconImage,
    bool? isSaving,
    bool? isPickingIcon,
    String? errorMessage,
    bool clearError = false,
    bool clearIcon = false,
  }) {
    return AppSettingsReady(
      editingApp: editingApp,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      iconImage: clearIcon ? null : (iconImage ?? this.iconImage),
      isSaving: isSaving ?? this.isSaving,
      isPickingIcon: isPickingIcon ?? this.isPickingIcon,
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
