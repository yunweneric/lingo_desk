import 'package:get_it/get_it.dart';

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
/// 1. Data sources (singletons)
/// 2. Repositories (singletons)
/// 3. Use cases (singletons or factories)
/// 4. BLoCs (factories - new instance per widget)
Future<void> init() async {
  // ==========================================
  // Data Sources
  // ==========================================
  // Register data sources as singletons
  // Example:
  // getIt.registerLazySingleton<LocalDataSource>(
  //   () => LocalDataSourceImpl(),
  // );
  // getIt.registerLazySingleton<RemoteDataSource>(
  //   () => RemoteDataSourceImpl(),
  // );

  // ==========================================
  // Repositories
  // ==========================================
  // Register repositories as singletons
  // Example:
  // getIt.registerLazySingleton<AppRepository>(
  //   () => AppRepositoryImpl(
  //     localDataSource: getIt(),
  //     remoteDataSource: getIt(),
  //   ),
  // );

  // ==========================================
  // Use Cases
  // ==========================================
  // Register use cases as singletons or factories
  // Use singleton if stateless, factory if stateful
  // Example:
  // getIt.registerLazySingleton(
  //   () => GetAppsUseCase(getIt()),
  // );
  // getIt.registerLazySingleton(
  //   () => CreateAppUseCase(getIt()),
  // );
  // getIt.registerLazySingleton(
  //   () => UpdateAppUseCase(getIt()),
  // );
  // getIt.registerLazySingleton(
  //   () => DeleteAppUseCase(getIt()),
  // );

  // ==========================================
  // BLoCs
  // ==========================================
  // Register BLoCs as factories (new instance per widget)
  // Example:
  // getIt.registerFactory(
  //   () => AppManagementBloc(
  //     getAppsUseCase: getIt(),
  //     createAppUseCase: getIt(),
  //     updateAppUseCase: getIt(),
  //     deleteAppUseCase: getIt(),
  //   ),
  // );
}

/// Resets the dependency injection container
///
/// Useful for testing or when you need to re-register dependencies.
/// This will unregister all dependencies and allow re-initialization.
Future<void> reset() async {
  await getIt.reset();
}
