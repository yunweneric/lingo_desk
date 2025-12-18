# Nomenclature Guide

This document defines the naming conventions for files, folders, variables, classes, and other code elements in the LingoDesk project.

## Table of Contents

- [File Naming](#file-naming)
- [Folder Naming](#folder-naming)
- [Class Naming](#class-naming)
- [Variable Naming](#variable-naming)
- [Function/Method Naming](#functionmethod-naming)
- [Constant Naming](#constant-naming)
- [Package/Import Naming](#packageimport-naming)
- [Test Naming](#test-naming)
- [BLoC Naming](#bloc-naming)
- [Barrel Files](#barrel-files)

## File Naming

### Dart Files

- **Format**: `snake_case.dart`
- **Examples**:
  - `app_management_bloc.dart`
  - `app_repository_impl.dart`
  - `get_apps_use_case.dart`
  - `app_management_page.dart`

### File Suffixes

Use consistent suffixes to indicate file purpose:

- **Entities**: `app.dart`, `translation.dart` (no suffix)
- **Models**: `app_model.dart`, `translation_model.dart`
- **Repositories (Interface)**: `app_repository.dart`
- **Repositories (Implementation)**: `app_repository_impl.dart`
- **Data Sources**: `local_data_source.dart`, `remote_data_source.dart`
- **Use Cases**: `get_apps.dart`, `create_app.dart` (verb + noun)
- **BLoC**: `app_management_bloc.dart`, `app_management_event.dart`, `app_management_state.dart`
- **Pages**: `app_management_page.dart`
- **Widgets**: `app_list_widget.dart`, `app_card_widget.dart`
- **Tests**: `app_management_bloc_test.dart`, `get_apps_test.dart`

### Special Files

- **Main entry**: `main.dart`
- **App widget**: `app.dart`
- **Bootstrap**: `bootstrap.dart`
- **Injection container**: `injection_container.dart`
- **Barrel files**: `export.dart` (used for clean imports)

## Folder Naming

### Feature Folders

- **Format**: `snake_case`
- **Examples**:
  - `app_management/`
  - `translation_editor/`
  - `file_upload/`

### Layer Folders

Use lowercase, singular names:

- `data/`
- `domain/`
- `presentation/`
- `datasources/`
- `models/`
- `repositories/`
- `entities/`
- `usecases/`
- `bloc/`
- `pages/`
- `widgets/`

### Core Folders

- `core/`
- `constants/`
- `errors/`
- `utils/`
- `di/` (dependency injection)

## Class Naming

### General Classes

- **Format**: `PascalCase`
- **Examples**:
  - `AppManagementBloc`
  - `AppRepository`
  - `AppRepositoryImpl`
  - `GetApps`
  - `AppModel`

### Entity Classes

- **Format**: `PascalCase`, singular noun
- **Examples**:
  - `App`
  - `Translation`
  - `Language`
  - `TranslationKey`

### Model Classes

- **Format**: `PascalCase` with `Model` suffix
- **Examples**:
  - `AppModel`
  - `TranslationModel`
  - `LanguageModel`

### Repository Classes

- **Interface**: `PascalCase` with `Repository` suffix
  - `AppRepository`
  - `TranslationRepository`
- **Implementation**: `PascalCase` with `RepositoryImpl` suffix
  - `AppRepositoryImpl`
  - `TranslationRepositoryImpl`

### Use Case Classes

- **Format**: `PascalCase`, verb + noun (imperative)
- **Examples**:
  - `GetApps`
  - `CreateApp`
  - `UpdateApp`
  - `DeleteApp`
  - `GetTranslations`

### BLoC Classes

- **BLoC**: `PascalCase` with `Bloc` suffix
  - `AppManagementBloc`
  - `TranslationEditorBloc`
- **Event**: `PascalCase` with `Event` suffix
  - `GetAppsEvent`
  - `CreateAppEvent`
- **State**: `PascalCase` with `State` suffix
  - `AppManagementInitial`
  - `AppManagementLoaded`
  - `AppManagementError`

### Page Classes

- **Format**: `PascalCase` with `Page` suffix
- **Examples**:
  - `AppManagementPage`
  - `TranslationEditorPage`
  - `FileUploadPage`

### Widget Classes

- **Format**: `PascalCase` with `Widget` suffix
- **Examples**:
  - `AppListWidget`
  - `AppCardWidget`
  - `TranslationGridWidget`

### Exception/Error Classes

- **Format**: `PascalCase` with `Exception` or `Failure` suffix
- **Examples**:
  - `CacheFailure`
  - `ServerFailure`
  - `NetworkException`

## Variable Naming

### Local Variables

- **Format**: `camelCase`
- **Examples**:
  - `appList`
  - `selectedApp`
  - `isLoading`
  - `translationKey`

### Private Variables

- **Format**: `camelCase` with `_` prefix
- **Examples**:
  - `_appRepository`
  - `_isInitialized`
  - `_currentIndex`

### Final Variables

- **Format**: `camelCase` (same as regular variables)
- **Examples**:
  - `final appName = 'My App';`
  - `final maxRetries = 3;`

### Static Variables

- **Format**: `camelCase` (same as regular variables)
- **Examples**:
  - `static const defaultLanguage = 'en';`

### Boolean Variables

- **Format**: `camelCase` with `is`, `has`, `should`, `can` prefix
- **Examples**:
  - `isLoading`
  - `hasError`
  - `shouldRefresh`
  - `canEdit`

### List/Collection Variables

- **Format**: `camelCase` with plural noun
- **Examples**:
  - `apps`
  - `translations`
  - `targetLanguages`
  - `appList` (if you need to be explicit)

## Function/Method Naming

### Public Methods

- **Format**: `camelCase`, verb-based
- **Examples**:
  - `getApps()`
  - `createApp()`
  - `updateTranslation()`
  - `deleteApp()`

### Private Methods

- **Format**: `camelCase` with `_` prefix
- **Examples**:
  - `_initializeRepository()`
  - `_handleError()`
  - `_validateInput()`

### Async Methods

- **Format**: `camelCase` (same as regular methods)
- **Examples**:
  - `Future<List<App>> getApps() async {}`
  - `Future<void> saveApp() async {}`

### Callback Methods

- **Format**: `camelCase` with `on` prefix for event handlers
- **Examples**:
  - `onAppSelected()`
  - `onDeletePressed()`
  - `onSave()`

### BLoC Event Handlers

- **Format**: `_on` prefix + event name in camelCase
- **Examples**:
  - `_onGetApps()`
  - `_onCreateApp()`
  - `_onDeleteApp()`

## Constant Naming

### Top-Level Constants

- **Format**: `lowerCamelCase` (Dart convention)
- **Examples**:
  - `const defaultLanguage = 'en';`
  - `const maxFileSize = 1024;`

### Class Constants

- **Format**: `lowerCamelCase` (Dart convention)
- **Examples**:
  ```dart
  class AppConstants {
    static const defaultLanguage = 'en';
    static const maxRetries = 3;
  }
  ```

### Enum Values

- **Format**: `camelCase`
- **Examples**:
  ```dart
  enum AppStatus {
    initial,
    loading,
    loaded,
    error,
  }
  ```

## Package/Import Naming

### Import Order

1. Dart SDK imports
2. Flutter imports
3. Package imports (pub.dev)
4. Project imports (relative)

### Import Format

```dart
// Dart SDK
import 'dart:async';
import 'dart:convert';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Packages
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';

// Project (absolute)
import 'package:lingo_desk/core/di/injection_container.dart';
import 'package:lingo_desk/features/app_management/domain/entities/app.dart';

// Project (relative)
import '../widgets/app_list_widget.dart';
```

## Test Naming

### Test Files

- **Format**: `snake_case` with `_test.dart` suffix
- **Examples**:
  - `app_management_bloc_test.dart`
  - `get_apps_test.dart`
  - `app_management_page_test.dart`

### Test Groups

- **Format**: `PascalCase` class/feature name
- **Examples**:
  ```dart
  group('AppManagementBloc', () {
    // tests
  });
  ```

### Test Cases

- **Format**: `lowercase` with underscores, descriptive
- **Examples**:

  ```dart
  test('should emit loading then loaded when GetAppsEvent is added', () {
    // test
  });

  testWidgets('displays app list when apps are loaded', (tester) async {
    // test
  });
  ```

## BLoC Naming

### Event Naming

- **Format**: `PascalCase` with `Event` suffix
- **Pattern**: Action + Entity/Resource
- **Examples**:
  - `GetAppsEvent`
  - `CreateAppEvent`
  - `UpdateAppEvent`
  - `DeleteAppEvent`
  - `RefreshAppsEvent`

### State Naming

- **Format**: `PascalCase` with descriptive suffix
- **Pattern**: FeatureName + StateType
- **Examples**:
  - `AppManagementInitial`
  - `AppManagementLoading`
  - `AppManagementLoaded`
  - `AppManagementError`
  - `AppManagementEmpty`

### BLoC Naming

- **Format**: `PascalCase` with `Bloc` suffix
- **Pattern**: FeatureName + Bloc
- **Examples**:
  - `AppManagementBloc`
  - `TranslationEditorBloc`
  - `FileUploadBloc`

## Naming Patterns Summary

| Type                      | Format                     | Example                    |
| ------------------------- | -------------------------- | -------------------------- |
| File                      | `snake_case.dart`          | `app_management_bloc.dart` |
| Folder                    | `snake_case/`              | `app_management/`          |
| Class                     | `PascalCase`               | `AppManagementBloc`        |
| Variable                  | `camelCase`                | `appList`                  |
| Private Variable          | `_camelCase`               | `_appRepository`           |
| Function                  | `camelCase`                | `getApps()`                |
| Private Function          | `_camelCase`               | `_handleError()`           |
| Constant                  | `lowerCamelCase`           | `defaultLanguage`          |
| Enum                      | `camelCase`                | `AppStatus.loading`        |
| Test File                 | `snake_case_test.dart`     | `app_management_test.dart` |
| BLoC Event                | `PascalCaseEvent`          | `GetAppsEvent`             |
| BLoC State                | `PascalCaseState`          | `AppManagementLoaded`      |
| Model                     | `PascalCaseModel`          | `AppModel`                 |
| Repository Interface      | `PascalCaseRepository`     | `AppRepository`            |
| Repository Implementation | `PascalCaseRepositoryImpl` | `AppRepositoryImpl`        |
| Use Case                  | `PascalCase` (verb)        | `GetApps`                  |
| Barrel File               | `export.dart`              | `export.dart`              |

## Common Mistakes to Avoid

1. ❌ **Don't use**: `AppManagementBLoC` (inconsistent casing)
   ✅ **Use**: `AppManagementBloc`

2. ❌ **Don't use**: `app_management_bloc.dart` for class name
   ✅ **Use**: `AppManagementBloc` for class, `app_management_bloc.dart` for file

3. ❌ **Don't use**: `GetAppsUseCase` (redundant suffix)
   ✅ **Use**: `GetApps` (use case is implied by location)

4. ❌ **Don't use**: `app_list` for a class
   ✅ **Use**: `AppListWidget` for class, `app_list_widget.dart` for file

5. ❌ **Don't use**: `APP_CONSTANT` (SCREAMING_SNAKE_CASE)
   ✅ **Use**: `defaultLanguage` (lowerCamelCase)

6. ❌ **Don't use**: `get_apps()` for method name
   ✅ **Use**: `getApps()` (camelCase)

7. ❌ **Don't use**: Multiple import statements for the same feature
   ✅ **Use**: Barrel files (`export.dart`) for clean imports

8. ❌ **Don't use**: `index.dart` or `barrel.dart` for barrel files
   ✅ **Use**: `export.dart` (consistent naming)

## Barrel Files

Barrel files are named `export.dart` and are used to create clean import statements.

### Barrel File Naming

- **Format**: Always named `export.dart`
- **Location**: One in each subdirectory and layer
- **Purpose**: Export all public APIs from that directory

### Barrel File Structure

Each directory should have an `export.dart` file that exports all public files:

```
lib/features/app_management/
├── data/
│   ├── datasources/
│   │   ├── local_data_source.dart
│   │   └── export.dart                    # Barrel file
│   ├── models/
│   │   ├── app_model.dart
│   │   └── export.dart                    # Barrel file
│   ├── repositories/
│   │   ├── app_repository_impl.dart
│   │   └── export.dart                    # Barrel file
│   └── export.dart                        # Main data layer barrel
├── domain/
│   ├── entities/
│   │   ├── app.dart
│   │   └── export.dart                    # Barrel file
│   ├── repositories/
│   │   ├── app_repository.dart
│   │   └── export.dart                    # Barrel file
│   ├── usecases/
│   │   ├── get_apps.dart
│   │   ├── create_app.dart
│   │   └── export.dart                    # Barrel file
│   └── export.dart                        # Main domain layer barrel
└── presentation/
    ├── bloc/
    │   ├── app_management_bloc.dart
    │   ├── app_management_event.dart
    │   ├── app_management_state.dart
    │   └── export.dart                    # Barrel file
    ├── pages/
    │   ├── app_management_page.dart
    │   └── export.dart                    # Barrel file
    ├── widgets/
    │   ├── app_list_widget.dart
    │   └── export.dart                    # Barrel file
    └── export.dart                        # Main presentation layer barrel
```

### Barrel File Content Example

**`lib/features/app_management/domain/entities/export.dart`**

```dart
export 'app.dart';
export 'translation.dart';
```

**`lib/features/app_management/domain/export.dart`**

```dart
// Entities
export 'entities/export.dart';

// Repository interfaces
export 'repositories/export.dart';

// Use cases
export 'usecases/export.dart';
```

### Import Usage

Instead of multiple imports:

```dart
import 'package:lingo_desk/features/app_management/domain/entities/app.dart';
import 'package:lingo_desk/features/app_management/domain/repositories/app_repository.dart';
```

Use barrel files:

```dart
import 'package:lingo_desk/features/app_management/domain/export.dart';
```

## File Organization Example

```
lib/features/app_management/
├── data/
│   ├── datasources/
│   │   ├── local_data_source.dart          # snake_case
│   │   └── export.dart                     # Barrel file
│   ├── models/
│   │   ├── app_model.dart                  # snake_case
│   │   └── export.dart                     # Barrel file
│   ├── repositories/
│   │   ├── app_repository_impl.dart        # snake_case
│   │   └── export.dart                     # Barrel file
│   └── export.dart                         # Main data barrel
├── domain/
│   ├── entities/
│   │   ├── app.dart                        # snake_case (singular)
│   │   └── export.dart                     # Barrel file
│   ├── repositories/
│   │   ├── app_repository.dart              # snake_case
│   │   └── export.dart                     # Barrel file
│   ├── usecases/
│   │   ├── get_apps.dart                   # snake_case
│   │   ├── create_app.dart                 # snake_case
│   │   └── export.dart                     # Barrel file
│   └── export.dart                         # Main domain barrel
└── presentation/
    ├── bloc/
    │   ├── app_management_bloc.dart        # snake_case
    │   ├── app_management_event.dart        # snake_case
    │   ├── app_management_state.dart         # snake_case
    │   └── export.dart                     # Barrel file
    ├── pages/
    │   ├── app_management_page.dart         # snake_case
    │   └── export.dart                     # Barrel file
    └── widgets/
        ├── app_list_widget.dart            # snake_case
        └── export.dart                     # Barrel file
```

## Enforcement

These naming conventions are enforced through:

1. **Linter Rules** (see `analysis_options.yaml`)
2. **Code Reviews** - Reviewers should check naming consistency
3. **IDE Warnings** - Configure your IDE to show naming violations
