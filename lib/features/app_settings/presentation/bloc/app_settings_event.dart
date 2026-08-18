import '../../../app_management/domain/entities/app.dart';

abstract class AppSettingsEvent {}

/// Initializes the form; [app] is null when creating a new app.
class InitializeAppSettingsEvent extends AppSettingsEvent {
  InitializeAppSettingsEvent({this.app, this.defaultTargetLanguages});

  final App? app;

  /// Targets to pre-select in create mode, from the workspace settings.
  final List<String>? defaultTargetLanguages;
}

/// Selects the source language.
class SourceLanguageChangedEvent extends AppSettingsEvent {
  SourceLanguageChangedEvent(this.languageCode);

  final String languageCode;
}

/// Adds/removes a target language.
class TargetLanguageToggledEvent extends AppSettingsEvent {
  TargetLanguageToggledEvent(this.languageCode);

  final String languageCode;
}

/// Validates and saves the configuration.
class SaveAppSettingsEvent extends AppSettingsEvent {
  SaveAppSettingsEvent(this.name);

  final String name;
}
