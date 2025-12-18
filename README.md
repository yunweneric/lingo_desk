# LingoDesk: Localization Management Tool

LingoDesk is a lightweight, project-based translation manager designed to eliminate the manual overhead of syncing multiple JSON localization files. It provides a centralized UI to manage keys and translations across various languages with real-time progress tracking.

Built with **Flutter** for web, desktop, and mobile platforms.

## 🚀 The Problem

Developers often spend excessive time manually opening, editing, and syncing key-value pairs across `en.json`, `es.json`, `uk.json`, etc. This process is:

- **Error-prone**: Easy to miss keys or make typos
- **Time-consuming**: Requires opening multiple files and manually syncing
- **Inefficient**: Breaks the development flow and reduces productivity

## ✨ The Solution

LingoDesk offers a cross-platform workflow to:

- **Organize translations by "App" (Project)**: Group related translations together
- **Flatten complex nested JSON**: Convert nested structures into a manageable table format
- **Track translation completion**: Real-time progress percentages for each language
- **Export clean, nested JSON**: Generate production-ready files with proper structure

## 🛠 Tech Stack

- **Framework**: Flutter (Web, Desktop, Mobile)
- **Version Management**: FVM (Flutter Version Management)
- **State Management**: BLoC (Business Logic Component)
- **Architecture**: Clean Architecture
- **Storage**: Local storage (Hive/SharedPreferences)

## 📋 Prerequisites

- [Dart SDK](https://dart.dev/get-dart)
- [FVM](https://fvm.app/) (Flutter Version Management)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (managed via FVM)

## 🚦 Getting Started

### 1. Install FVM

```bash
# macOS/Linux
brew tap leoafarias/fvm
brew install fvm

# Or using pub
dart pub global activate fvm
```

### 2. Setup Flutter Version

```bash
# Navigate to project directory
cd lingo_desk

# Install Flutter version (check .fvm/fvm_config.json for required version)
fvm install

# Use the Flutter version for this project
fvm use <version>
```

### 3. Install Dependencies

```bash
# Use fvm to run flutter commands
fvm flutter pub get
```

### 4. Run the Application

```bash
# Web
fvm flutter run -d chrome

# Desktop (macOS)
fvm flutter run -d macos

# Desktop (Linux)
fvm flutter run -d linux

# Desktop (Windows)
fvm flutter run -d windows

# Mobile (iOS)
fvm flutter run -d ios

# Mobile (Android)
fvm flutter run -d android
```

## 🏗 Architecture

LingoDesk follows **Clean Architecture** principles with **BLoC** state management, organized in a **feature-based** folder structure.

### Clean Architecture Layers

```
lib/
├── core/                    # Core functionality
│   ├── constants/
│   ├── errors/
│   ├── usecases/
│   ├── utils/
│   └── widgets/
├── features/                # Feature modules
│   ├── app_management/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── export.dart    # Barrel file
│   │   │   ├── models/
│   │   │   │   └── export.dart    # Barrel file
│   │   │   ├── repositories/
│   │   │   │   └── export.dart    # Barrel file
│   │   │   └── export.dart        # Main data barrel
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── export.dart    # Barrel file
│   │   │   ├── repositories/
│   │   │   │   └── export.dart    # Barrel file
│   │   │   ├── usecases/
│   │   │   │   └── export.dart    # Barrel file
│   │   │   └── export.dart        # Main domain barrel
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── export.dart    # Barrel file
│   │       ├── pages/
│   │       │   └── export.dart    # Barrel file
│   │       ├── widgets/
│   │       │   └── export.dart    # Barrel file
│   │       └── export.dart        # Main presentation barrel
│   ├── app_settings/
│   ├── file_upload/
│   └── translation_editor/
└── main.dart
```

> **Note**: Each feature uses barrel files (`export.dart`) for clean imports. See [Feature Implementation Guide](docs/feature.md#barrel-files) for details.

### Layer Responsibilities

- **Presentation Layer**: UI, BLoC, Pages, Widgets
- **Domain Layer**: Business logic, Entities, Use cases, Repository interfaces
- **Data Layer**: Data sources, Models, Repository implementations

### BLoC State Management

Each feature uses BLoC pattern for state management:

```
feature/
└── presentation/
    └── bloc/
        ├── feature_bloc.dart
        ├── feature_event.dart
        └── feature_state.dart
```

## 📱 Application Flow

LingoDesk follows a 4-screen flow designed for an intuitive translation management experience.

### 1. App Management Dashboard

The entry point of the application.

- **CRUD for Apps**: Create, view, update, or delete localization projects
- **Persistence**: Project metadata is saved to local storage so your project list persists across sessions
- **Overview**: See high-level completion status for each app

### 2. App Settings

Configure the specific requirements for an App.

- **Source Language**: Set the base language (e.g., `en`)
- **Target Languages**: Define languages to translate into (e.g., `uk`, `es`, `ru`)
- **Project Configuration**: Update project naming and language scope

### 3. File Initialization (Upload)

A dedicated stage to sync your local code with the editor.

- **Context-Aware**: Displays the specific languages required for the selected App
- **Validation**: Ensures files match the expected language codes before proceeding
- **File Upload**: Import existing JSON files to populate the editor

### 4. Translation Editor (The Workspace)

The core engine of LingoDesk.

- **Flattened Grid**: A unified table where each row is a translation key
- **Progress Widget**: Real-time completion bars for every target language
- **"Show Missing Only"**: A filter to instantly isolate untranslated strings
- **CRUD on Keys**: Add new keys or delete obsolete ones across all languages simultaneously
- **JSON Export**: Re-constructs the nested JSON structure and triggers downloads

## ⚙️ Technical Specifications

### Data Transformation

**Flattening**: Converts nested JSON into dot-notation format
```json
// Input
{
  "nav": {
    "home": "Home"
  }
}

// Output
{
  "nav.home": "Home"
}
```

**Un-flattening**: Reverses dot-notation back into deep objects upon export

**In-Memory State**: Translation content is handled in-session for maximum speed and privacy

### Core Features

- **Missing Indicator**: Automatic UI highlighting for empty fields
- **Confirmation Guards**: Destructive actions (deleting keys or apps) are protected by warning modals
- **Frontend-Only**: No backend required. Your data stays locally

## 🧪 Testing

The project includes comprehensive testing setup for unit tests, widget tests, and integration tests.

### Running Tests

```bash
# Run all tests
fvm flutter test

# Run unit tests only
fvm flutter test test/unit

# Run widget tests only
fvm flutter test test/widget

# Run integration tests
fvm flutter test integration_test

# Run specific test file
fvm flutter test test/unit/core/bootstrap_test.dart

# Using test scripts
./scripts/test.sh all          # Run all tests
./scripts/test.sh unit          # Run unit tests
./scripts/test.sh widget        # Run widget tests
./scripts/test.sh integration   # Run integration tests
./scripts/test.sh coverage      # Run with coverage
```

### Test Coverage

```bash
# Generate coverage report
fvm flutter test --coverage

# Generate and view HTML coverage report
./scripts/test_coverage.sh

# Or manually (requires lcov)
fvm flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Structure

```
test/
├── helpers/              # Test utilities and helpers
│   ├── test_helpers.dart
│   ├── mock_factories.dart
│   └── bloc_test_helpers.dart
├── unit/                 # Unit tests
│   └── core/
└── widget/               # Widget tests
    └── core/

integration_test/         # Integration tests
└── app_test.dart
```

### Test Types

- **Unit Tests**: Test individual functions, classes, and use cases in isolation
- **Widget Tests**: Test individual widgets and their interactions
- **Integration Tests**: Test complete user flows and app behavior

See [test/README.md](test/README.md) for detailed testing documentation.

## 📦 Building

```bash
# Web
fvm flutter build web

# Desktop (macOS)
fvm flutter build macos

# Desktop (Linux)
fvm flutter build linux

# Desktop (Windows)
fvm flutter build windows

# Mobile (iOS)
fvm flutter build ios

# Mobile (Android)
fvm flutter build apk
# or
fvm flutter build appbundle
```

## 🤝 Contributing

We welcome contributions to LingoDesk! Please follow these guidelines:

### Getting Started

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/your-username/lingo_desk.git
   cd lingo_desk
   ```
3. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Setup the project**
   ```bash
   fvm install
   fvm use <version>
   fvm flutter pub get
   ```

### Development Guidelines

- **Follow Clean Architecture**: Maintain separation between presentation, domain, and data layers
- **Use BLoC Pattern**: Implement state management using BLoC for all features
- **Feature-Based Structure**: Organize code by features, not by file types
- **Write Tests**: Add unit tests for use cases and widget tests for UI components
- **Follow Dart Style Guide**: Use `dart format` and follow the project's `analysis_options.yaml`
- **Write Documentation**: Document complex logic and public APIs

### Code Style

```bash
# Format code
fvm dart format .

# Analyze code
fvm flutter analyze
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc.)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

### Pull Request Process

1. **Update your branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-branch
   git rebase main
   ```

2. **Ensure tests pass**
   ```bash
   fvm flutter test
   fvm flutter analyze
   ```

3. **Create Pull Request**
   - Provide a clear description of changes
   - Reference any related issues
   - Include screenshots for UI changes
   - Ensure CI checks pass

### Reporting Issues

When reporting issues, please include:

- **Platform**: Web, Desktop (OS), or Mobile (OS)
- **Flutter Version**: Output of `fvm flutter --version`
- **Steps to Reproduce**: Clear steps to reproduce the issue
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Screenshots**: If applicable

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## 🙏 Acknowledgments

LingoDesk was prototyped and specified using an iterative blueprinting process to ensure a rock-solid development path.

---

**Made with ❤️ using Flutter**
