# Feature Implementation Guide

This guide explains how to implement a typical feature following Clean Architecture principles with BLoC state management in LingoDesk.

## Table of Contents

- [Feature Structure](#feature-structure)
- [Implementation Steps](#implementation-steps)
- [Layer-by-Layer Guide](#layer-by-layer-guide)
- [Dependency Injection](#dependency-injection)
- [Testing](#testing)
- [Best Practices](#best-practices)

## Feature Structure

Each feature follows a consistent structure with three main layers and barrel files for clean imports:

```
lib/features/
└── feature_name/
    ├── data/                    # Data Layer
    │   ├── datasources/        # Local/Remote data sources
    │   │   └── export.dart     # Barrel file for data sources
    │   ├── models/              # Data models (JSON serialization)
    │   │   └── export.dart     # Barrel file for models
    │   ├── repositories/        # Repository implementations
    │   │   └── export.dart     # Barrel file for repositories
    │   └── export.dart          # Barrel file for entire data layer
    ├── domain/                  # Domain Layer (Business Logic)
    │   ├── entities/            # Business entities
    │   │   └── export.dart     # Barrel file for entities
    │   ├── repositories/         # Repository interfaces
    │   │   └── export.dart     # Barrel file for repository interfaces
    │   ├── usecases/            # Business logic use cases
    │   │   └── export.dart     # Barrel file for use cases
    │   └── export.dart          # Barrel file for entire domain layer
    └── presentation/            # Presentation Layer (UI)
        ├── bloc/                # BLoC files (bloc, event, state)
        │   └── export.dart     # Barrel file for BLoC
        ├── pages/                # Feature pages/screens
        │   └── export.dart     # Barrel file for pages
        ├── widgets/              # Feature-specific widgets
        │   └── export.dart     # Barrel file for widgets
        └── export.dart          # Barrel file for entire presentation layer
```

## Implementation Steps

Follow these steps in order when implementing a new feature:

1. **Domain Layer** (Start here - no dependencies)

   - Create entities
   - Define repository interfaces
   - Create use cases

2. **Data Layer** (Depends on domain)

   - Create models (extend entities)
   - Implement data sources
   - Implement repositories

3. **Presentation Layer** (Depends on domain)

   - Create BLoC (events, states, bloc)
   - Create pages
   - Create widgets

4. **Create Barrel Files**

   - Create `export.dart` files for each layer and subdirectory
   - Export all public APIs to enable clean imports

5. **Dependency Injection**

   - Register all dependencies in `injection_container.dart`

6. **Testing**
   - Write unit tests for use cases
   - Write widget tests for UI
   - Write BLoC tests

## Layer-by-Layer Guide

### 1. Domain Layer

The domain layer contains pure business logic with no dependencies on Flutter or external frameworks.

#### Entities

Entities represent core business objects. They should be simple Dart classes.

**Example: `lib/features/app_management/domain/entities/app.dart`**

```dart
class App {
  final String id;
  final String name;
  final String sourceLanguage;
  final List<String> targetLanguages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const App({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguages,
    required this.createdAt,
    required this.updatedAt,
  });
}
```

#### Repository Interfaces

Define what data operations your feature needs. These are abstract classes.

**Example: `lib/features/app_management/domain/repositories/app_repository.dart`**

```dart
import '../entities/app.dart';
import '../../../../core/errors/failures.dart';
import 'package:dartz/dartz.dart';

abstract class AppRepository {
  Future<Either<Failure, List<App>>> getApps();
  Future<Either<Failure, App>> getAppById(String id);
  Future<Either<Failure, App>> createApp(App app);
  Future<Either<Failure, App>> updateApp(App app);
  Future<Either<Failure, void>> deleteApp(String id);
}
```

**Note:** We use `Either<Failure, T>` from the `dartz` package for error handling. You'll need to add it to `pubspec.yaml`:

```yaml
dependencies:
  dartz: ^0.10.1
```

#### Use Cases

Use cases contain specific business logic. Each use case should do one thing.

**Example: `lib/features/app_management/domain/usecases/get_apps.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/app.dart';
import '../repositories/app_repository.dart';

class GetApps implements UseCase<List<App>, NoParams> {
  final AppRepository repository;

  GetApps(this.repository);

  @override
  Future<Either<Failure, List<App>>> call(NoParams params) async {
    return await repository.getApps();
  }
}
```

**Base UseCase: `lib/core/usecases/usecase.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {
  const NoParams();
}
```

### 2. Data Layer

The data layer implements the domain interfaces and handles data operations.

#### Models

Models extend entities and add JSON serialization. They convert between JSON and entities.

**Example: `lib/features/app_management/data/models/app_model.dart`**

```dart
import '../../domain/entities/app.dart';

class AppModel extends App {
  const AppModel({
    required super.id,
    required super.name,
    required super.sourceLanguage,
    required super.targetLanguages,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'],
      name: json['name'],
      sourceLanguage: json['sourceLanguage'],
      targetLanguages: List<String>.from(json['targetLanguages']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sourceLanguage': sourceLanguage,
      'targetLanguages': targetLanguages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AppModel copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    List<String>? targetLanguages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguages: targetLanguages ?? this.targetLanguages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

#### Data Sources

Data sources handle the actual data operations (local storage, API calls, etc.).

**Example: `lib/features/app_management/data/datasources/local_data_source.dart`**

```dart
abstract class LocalDataSource {
  Future<List<Map<String, dynamic>>> getApps();
  Future<Map<String, dynamic>?> getAppById(String id);
  Future<Map<String, dynamic>> createApp(Map<String, dynamic> app);
  Future<Map<String, dynamic>> updateApp(Map<String, dynamic> app);
  Future<void> deleteApp(String id);
}

class LocalDataSourceImpl implements LocalDataSource {
  // Implementation using SharedPreferences, Hive, etc.
  // Example with SharedPreferences:

  @override
  Future<List<Map<String, dynamic>>> getApps() async {
    // Implementation
    return [];
  }

  // ... other methods
}
```

#### Repository Implementation

Repositories implement the domain repository interface and coordinate data sources.

**Example: `lib/features/app_management/data/repositories/app_repository_impl.dart`**

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/app.dart';
import '../../domain/repositories/app_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/app_model.dart';

class AppRepositoryImpl implements AppRepository {
  final LocalDataSource localDataSource;

  AppRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<App>>> getApps() async {
    try {
      final appsJson = await localDataSource.getApps();
      final apps = appsJson
          .map((json) => AppModel.fromJson(json))
          .toList();
      return Right(apps);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  // ... implement other methods
}
```

### 3. Presentation Layer

The presentation layer handles UI and state management using BLoC.

#### BLoC Events

Events represent user actions or system events.

**Example: `lib/features/app_management/presentation/bloc/app_management_event.dart`**

```dart
abstract class AppManagementEvent {}

class GetAppsEvent extends AppManagementEvent {}

class CreateAppEvent extends AppManagementEvent {
  final String name;
  final String sourceLanguage;
  final List<String> targetLanguages;

  CreateAppEvent({
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguages,
  });
}

class DeleteAppEvent extends AppManagementEvent {
  final String appId;

  DeleteAppEvent(this.appId);
}
```

#### BLoC States

States represent the UI state at any given time.

**Example: `lib/features/app_management/presentation/bloc/app_management_state.dart`**

```dart
abstract class AppManagementState {}

class AppManagementInitial extends AppManagementState {}

class AppManagementLoading extends AppManagementState {}

class AppManagementLoaded extends AppManagementState {
  final List<App> apps;

  AppManagementLoaded(this.apps);
}

class AppManagementError extends AppManagementState {
  final String message;

  AppManagementError(this.message);
}
```

#### BLoC

The BLoC handles business logic and emits states based on events.

**Example: `lib/features/app_management/presentation/bloc/app_management_bloc.dart`**

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app.dart';
import '../../domain/usecases/get_apps.dart';
import '../../domain/usecases/create_app.dart';
import '../../domain/usecases/delete_app.dart';
import '../../../../core/usecases/usecase.dart';
import 'app_management_event.dart';
import 'app_management_state.dart';

class AppManagementBloc
    extends Bloc<AppManagementEvent, AppManagementState> {
  final GetApps getApps;
  final CreateApp createApp;
  final DeleteApp deleteApp;

  AppManagementBloc({
    required this.getApps,
    required this.createApp,
    required this.deleteApp,
  }) : super(AppManagementInitial()) {
    on<GetAppsEvent>(_onGetApps);
    on<CreateAppEvent>(_onCreateApp);
    on<DeleteAppEvent>(_onDeleteApp);
  }

  Future<void> _onGetApps(
    GetAppsEvent event,
    Emitter<AppManagementState> emit,
  ) async {
    emit(AppManagementLoading());
    final result = await getApps(NoParams());
    result.fold(
      (failure) => emit(AppManagementError(failure.message)),
      (apps) => emit(AppManagementLoaded(apps)),
    );
  }

  Future<void> _onCreateApp(
    CreateAppEvent event,
    Emitter<AppManagementState> emit,
  ) async {
    // Implementation
  }

  Future<void> _onDeleteApp(
    DeleteAppEvent event,
    Emitter<AppManagementState> emit,
  ) async {
    // Implementation
  }
}
```

#### Pages

Pages are the main screens of your feature.

**Example: `lib/features/app_management/presentation/pages/app_management_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/app_management_bloc.dart';
import '../bloc/app_management_event.dart';
import '../bloc/app_management_state.dart';
import '../widgets/app_list_widget.dart';

class AppManagementPage extends StatelessWidget {
  const AppManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AppManagementBloc>()
        ..add(GetAppsEvent()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('App Management'),
        ),
        body: BlocBuilder<AppManagementBloc, AppManagementState>(
          builder: (context, state) {
            if (state is AppManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AppManagementError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is AppManagementLoaded) {
              return AppListWidget(apps: state.apps);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

#### Widgets

Feature-specific widgets that are reusable within the feature.

**Example: `lib/features/app_management/presentation/widgets/app_list_widget.dart`**

```dart
import 'package:flutter/material.dart';
import '../../domain/entities/app.dart';

class AppListWidget extends StatelessWidget {
  final List<App> apps;

  const AppListWidget({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        return ListTile(
          title: Text(app.name),
          subtitle: Text('${app.sourceLanguage} → ${app.targetLanguages.join(", ")}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Handle delete
            },
          ),
        );
      },
    );
  }
}
```

## Barrel Files

Barrel files (`export.dart`) are used to create clean, organized import statements. Each layer and subdirectory should have an `export.dart` file that exports all public APIs.

### Why Use Barrel Files?

- **Clean Imports**: Instead of multiple import statements, use a single import
- **Encapsulation**: Hide internal implementation details
- **Easier Refactoring**: Change internal structure without affecting imports
- **Better Organization**: Clear public API for each layer

### Barrel File Structure

Create `export.dart` files at multiple levels:

#### 1. Domain Layer Barrel Files

**`lib/features/app_management/domain/entities/export.dart`**

```dart
export 'app.dart';
export 'translation.dart';
// Export all entity files
```

**`lib/features/app_management/domain/repositories/export.dart`**

```dart
export 'app_repository.dart';
// Export all repository interface files
```

**`lib/features/app_management/domain/usecases/export.dart`**

```dart
export 'get_apps.dart';
export 'create_app.dart';
export 'update_app.dart';
export 'delete_app.dart';
// Export all use case files
```

**`lib/features/app_management/domain/export.dart`** (Main domain barrel)

```dart
// Entities
export 'entities/export.dart';

// Repository interfaces
export 'repositories/export.dart';

// Use cases
export 'usecases/export.dart';
```

#### 2. Data Layer Barrel Files

**`lib/features/app_management/data/models/export.dart`**

```dart
export 'app_model.dart';
export 'translation_model.dart';
// Export all model files
```

**`lib/features/app_management/data/datasources/export.dart`**

```dart
export 'local_data_source.dart';
// Export all data source files
```

**`lib/features/app_management/data/repositories/export.dart`**

```dart
export 'app_repository_impl.dart';
// Export all repository implementation files
```

**`lib/features/app_management/data/export.dart`** (Main data barrel)

```dart
// Models
export 'models/export.dart';

// Data sources
export 'datasources/export.dart';

// Repository implementations
export 'repositories/export.dart';
```

#### 3. Presentation Layer Barrel Files

**`lib/features/app_management/presentation/bloc/export.dart`**

```dart
export 'app_management_bloc.dart';
export 'app_management_event.dart';
export 'app_management_state.dart';
```

**`lib/features/app_management/presentation/pages/export.dart`**

```dart
export 'app_management_page.dart';
// Export all page files
```

**`lib/features/app_management/presentation/widgets/export.dart`**

```dart
export 'app_list_widget.dart';
export 'app_card_widget.dart';
// Export all widget files
```

**`lib/features/app_management/presentation/export.dart`** (Main presentation barrel)

```dart
// BLoC
export 'bloc/export.dart';

// Pages
export 'pages/export.dart';

// Widgets
export 'widgets/export.dart';
```

#### 4. Feature-Level Barrel File (Optional)

**`lib/features/app_management/export.dart`** (Main feature barrel)

```dart
// Domain layer (public API only)
export 'domain/export.dart';

// Presentation layer (for navigation/routing)
export 'presentation/pages/export.dart';
```

**Note**: Only export what's needed from outside the feature. Internal implementations should not be exported at the feature level.

### Using Barrel Files

Instead of:

```dart
import 'package:lingo_desk/features/app_management/domain/entities/app.dart';
import 'package:lingo_desk/features/app_management/domain/repositories/app_repository.dart';
import 'package:lingo_desk/features/app_management/domain/usecases/get_apps.dart';
```

Use:

```dart
import 'package:lingo_desk/features/app_management/domain/export.dart';
```

Or even better, if you only need specific parts:

```dart
import 'package:lingo_desk/features/app_management/domain/entities/export.dart';
import 'package:lingo_desk/features/app_management/domain/usecases/export.dart';
```

### Best Practices for Barrel Files

1. **Export Only Public APIs**: Don't export internal implementation details
2. **Keep It Simple**: Export files, not individual classes (unless necessary)
3. **Update Regularly**: Add new exports when adding new files
4. **Document Exports**: Use comments to group related exports
5. **Avoid Circular Dependencies**: Be careful not to create circular exports

## Dependency Injection

Register all dependencies in `lib/core/di/injection_container.dart`:

```dart
Future<void> init() async {
  // Data Sources
  getIt.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<AppRepository>(
    () => AppRepositoryImpl(
      localDataSource: getIt(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(() => GetApps(getIt()));
  getIt.registerLazySingleton(() => CreateApp(getIt()));
  getIt.registerLazySingleton(() => DeleteApp(getIt()));

  // BLoCs (factories - new instance per widget)
  getIt.registerFactory(
    () => AppManagementBloc(
      getApps: getIt(),
      createApp: getIt(),
      deleteApp: getIt(),
    ),
  );
}
```

## Testing

### Unit Tests for Use Cases

**Example: `test/unit/features/app_management/usecases/get_apps_test.dart`**

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lingo_desk/features/app_management/domain/entities/app.dart';
import 'package:lingo_desk/features/app_management/domain/repositories/app_repository.dart';
import 'package:lingo_desk/features/app_management/domain/usecases/get_apps.dart';
import 'package:lingo_desk/core/usecases/usecase.dart';

class MockAppRepository extends Mock implements AppRepository {}

void main() {
  late GetApps useCase;
  late MockAppRepository mockRepository;

  setUp(() {
    mockRepository = MockAppRepository();
    useCase = GetApps(mockRepository);
  });

  test('should get apps from repository', () async {
    // Arrange
    final tApps = [/* test apps */];
    when(mockRepository.getApps())
        .thenAnswer((_) async => Right(tApps));

    // Act
    final result = await useCase(NoParams());

    // Assert
    expect(result, Right(tApps));
    verify(mockRepository.getApps());
    verifyNoMoreInteractions(mockRepository);
  });
}
```

### BLoC Tests

**Example: `test/unit/features/app_management/presentation/bloc/app_management_bloc_test.dart`**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/features/app_management/presentation/bloc/app_management_bloc.dart';
// ... other imports

void main() {
  // Test implementation using bloc_test package
}
```

### Widget Tests

**Example: `test/widget/features/app_management/presentation/pages/app_management_page_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ... other imports

void main() {
  // Widget test implementation
}
```

## Best Practices

1. **Start with Domain Layer**: Always implement domain layer first (entities, repositories, use cases) as it has no dependencies.

2. **One Use Case = One Responsibility**: Each use case should do one specific thing.

3. **Use Either for Error Handling**: Use `Either<Failure, T>` from `dartz` package for consistent error handling.

4. **BLoCs are Factories**: Register BLoCs as factories in GetIt so each widget gets a new instance.

5. **Repositories are Singletons**: Register repositories as singletons since they're stateless.

6. **Models Extend Entities**: Models should extend entities and add serialization logic.

7. **Test Coverage**: Aim for >80% test coverage, especially for business logic.

8. **Feature Isolation**: Features should be independent and not directly depend on other features.

9. **Use Core Layer**: Share common functionality through the `core` layer (errors, use cases, widgets).

10. **Always Create Barrel Files**: Create `export.dart` files for each layer and subdirectory to enable clean imports.

11. **Naming Conventions**:
    - Entities: `App`, `Translation`
    - Models: `AppModel`, `TranslationModel`
    - Repositories: `AppRepository` (interface), `AppRepositoryImpl` (implementation)
    - Use Cases: `GetApps`, `CreateApp`
    - BLoCs: `AppManagementBloc`
    - Events: `GetAppsEvent`, `CreateAppEvent`
    - States: `AppManagementInitial`, `AppManagementLoaded`

## Example: Complete Feature Flow

1. User taps a button → **Event** is dispatched
2. BLoC receives event → Calls **Use Case**
3. Use Case calls **Repository** interface
4. Repository implementation calls **Data Source**
5. Data Source returns data → **Model** converts to **Entity**
6. Entity flows back through layers → **BLoC** emits **State**
7. UI rebuilds based on new **State**

This flow ensures separation of concerns and makes the code testable and maintainable.
