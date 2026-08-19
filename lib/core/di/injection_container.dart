import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/ai_translation/data/export.dart';
import '../../features/ai_translation/domain/export.dart';
import '../../features/app_management/data/export.dart';
import '../../features/app_management/domain/export.dart';
import '../../features/app_management/presentation/bloc/export.dart';
import '../../features/app_settings/presentation/bloc/export.dart';
import '../../features/file_upload/data/export.dart';
import '../../features/file_upload/domain/export.dart';
import '../../features/file_upload/presentation/bloc/export.dart';
import '../../features/translation_editor/data/export.dart';
import '../../features/translation_editor/domain/export.dart';
import '../../features/translation_editor/presentation/bloc/export.dart';
import '../preferences/ai_credential_store.dart';
import '../preferences/ai_settings_controller.dart';
import '../preferences/app_preferences.dart';
import '../preferences/app_settings_controller.dart';
import '../updates/update_controller.dart';
import '../updates/update_service.dart';

/// Global service locator instance
///
/// Use this instance to access registered dependencies throughout the app.
/// Example: `final repository = getIt<Repository>();`
final getIt = GetIt.instance;

/// Initializes dependency injection container
///
/// This function should be called during app bootstrap to register
/// all dependencies (repositories, data sources, use cases, BLoCs, etc.)
///
/// Registration order matters:
/// 1. External services (SharedPreferences)
/// 2. Data sources (singletons)
/// 3. Repositories (singletons)
/// 4. Use cases (singletons)
/// 5. BLoCs (factories - new instance per widget)
Future<void> init() async {
  // ==========================================
  // External
  // ==========================================
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  getIt.registerLazySingleton<AppPreferences>(() => AppPreferences(getIt()));
  getIt.registerLazySingleton<AppSettingsController>(
    () => AppSettingsController(getIt()),
  );
  getIt.registerLazySingleton<http.Client>(http.Client.new);
  // One controller for the whole run: the update check is remembered so
  // reopening the pane does not ask GitHub again.
  getIt.registerLazySingleton<UpdateService>(
    () => UpdateService(client: getIt()),
  );
  getIt.registerLazySingleton<UpdateController>(
    () => UpdateController(getIt()),
  );
  getIt.registerLazySingleton<AiCredentialStore>(
    () => AiCredentialStore(
      secureStorage: AiCredentialStore.defaultSecureStorage,
      preferences: getIt(),
    ),
  );
  // The API keys live in the platform keychain, which is async, so they are
  // read once here and cached; every later read is synchronous.
  final aiSettings = AiSettingsController(
    preferences: getIt(),
    credentialStore: getIt(),
  );
  await aiSettings.load();
  getIt.registerLazySingleton<AiSettingsController>(() => aiSettings);

  // ==========================================
  // Data Sources
  // ==========================================
  getIt.registerLazySingleton<AppIconDataSource>(
    () => const AppIconDataSourceImpl(),
  );
  getIt.registerLazySingleton<AppLocalDataSource>(
    () => AppLocalDataSourceImpl(preferences: getIt()),
  );
  getIt.registerLazySingleton<TranslationLocalDataSource>(
    () => TranslationLocalDataSourceImpl(preferences: getIt()),
  );
  getIt.registerLazySingleton<FileExportDataSource>(
    () => const FileExportDataSourceImpl(),
  );
  getIt.registerLazySingleton<FilePickerDataSource>(
    () => const FilePickerDataSourceImpl(),
  );
  getIt.registerLazySingleton<AnthropicClient>(() => AnthropicClient(getIt()));
  getIt.registerLazySingleton<OpenAiClient>(() => OpenAiClient(getIt()));
  getIt.registerLazySingleton<GeminiClient>(() => GeminiClient(getIt()));

  // ==========================================
  // Repositories
  // ==========================================
  getIt.registerLazySingleton<AppRepository>(
    () => AppRepositoryImpl(localDataSource: getIt()),
  );
  getIt.registerLazySingleton<AppIconRepository>(
    () => AppIconRepositoryImpl(dataSource: getIt()),
  );
  getIt.registerLazySingleton<TranslationRepository>(
    () => TranslationRepositoryImpl(
      localDataSource: getIt(),
      fileExportDataSource: getIt(),
    ),
  );
  getIt.registerLazySingleton<FileUploadRepository>(
    () => FileUploadRepositoryImpl(filePickerDataSource: getIt()),
  );
  getIt.registerLazySingleton<AiTranslationRepository>(
    () => AiTranslationRepositoryImpl(
      clients: {
        AiProvider.anthropic: getIt<AnthropicClient>(),
        AiProvider.openai: getIt<OpenAiClient>(),
        AiProvider.gemini: getIt<GeminiClient>(),
      },
    ),
  );

  // ==========================================
  // Use Cases
  // ==========================================
  // App management
  getIt.registerLazySingleton(() => GetAppOverviews(getIt()));
  getIt.registerLazySingleton(() => GetAppById(getIt()));
  getIt.registerLazySingleton(() => CreateApp(getIt()));
  getIt.registerLazySingleton(() => UpdateApp(getIt()));
  getIt.registerLazySingleton(() => DeleteApp(getIt()));
  getIt.registerLazySingleton(() => PickAppIcon(getIt()));

  // Translation editor
  getIt.registerLazySingleton(() => GetTranslations(getIt()));
  getIt.registerLazySingleton(() => SaveTranslations(getIt()));
  getIt.registerLazySingleton(() => UpdateTranslation(getIt()));
  getIt.registerLazySingleton(() => AddTranslationKey(getIt()));
  getIt.registerLazySingleton(() => DeleteTranslationKey(getIt()));
  getIt.registerLazySingleton(() => ExportTranslationsToDownloads(getIt()));
  getIt.registerLazySingleton(() => ExportTranslationsToFolder(getIt()));
  getIt.registerLazySingleton(() => PickExportFolder(getIt()));
  getIt.registerLazySingleton(() => RevealExportLocation(getIt()));

  // AI translation
  getIt.registerLazySingleton(() => TranslateBatch(getIt()));
  getIt.registerLazySingleton(() => VerifyAiCredentials(getIt()));

  // File upload
  getIt.registerLazySingleton(() => PickTranslationFiles(getIt()));
  getIt.registerLazySingleton(ParseTranslationFile.new);
  getIt.registerLazySingleton(() => ScanProjectFolder(getIt(), getIt()));

  // ==========================================
  // BLoCs
  // ==========================================
  getIt.registerFactory(
    () => AppManagementBloc(getAppOverviews: getIt(), deleteApp: getIt()),
  );
  getIt.registerFactory(
    () => AppSettingsBloc(
      createApp: getIt(),
      updateApp: getIt(),
      pickAppIcon: getIt(),
    ),
  );
  getIt.registerFactory(
    () => TranslationEditorBloc(
      getAppById: getIt(),
      getTranslations: getIt(),
      updateTranslation: getIt(),
      addTranslationKey: getIt(),
      deleteTranslationKey: getIt(),
      exportToDownloads: getIt(),
      exportToFolder: getIt(),
      pickExportFolder: getIt(),
      revealExportLocation: getIt(),
      saveTranslations: getIt(),
      translateBatch: getIt(),
      aiSettings: getIt(),
    ),
  );
  getIt.registerFactory(
    () => FileUploadBloc(
      pickTranslationFiles: getIt(),
      parseTranslationFile: getIt(),
      scanProjectFolder: getIt(),
      saveTranslations: getIt(),
      createApp: getIt(),
      updateApp: getIt(),
      pickAppIcon: getIt(),
      settings: getIt(),
    ),
  );
}

/// Resets the dependency injection container
///
/// Useful for testing or when you need to re-register dependencies.
/// This will unregister all dependencies and allow re-initialization.
Future<void> reset() async {
  await getIt.reset();
}
