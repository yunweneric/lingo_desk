# VS Code Configuration

This directory contains VS Code configuration files for the LingoDesk project.

## Files

- **launch.json** - Debug and run configurations
- **settings.json** - Workspace-specific settings
- **tasks.json** - Task definitions for common operations
- **extensions.json** - Recommended VS Code extensions

## Launch Configurations

### Running the App

Select a launch configuration from the debug panel (F5) or Run menu:

- **LingoDesk (Web)** - Run on Chrome
- **LingoDesk (macOS)** - Run on macOS desktop
- **LingoDesk (iOS)** - Run on iOS simulator/device
- **LingoDesk (Android)** - Run on Android emulator/device
- **LingoDesk (Linux)** - Run on Linux desktop
- **LingoDesk (Windows)** - Run on Windows desktop

### Running Tests

- **Run All Tests** - Run all unit and widget tests
- **Run Unit Tests** - Run only unit tests
- **Run Widget Tests** - Run only widget tests
- **Run Integration Tests** - Run integration tests
- **Run Tests with Coverage** - Run all tests and generate coverage
- **Debug Current Test File** - Debug the currently open test file

## Tasks

Access tasks via `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux) and type "Tasks: Run Task":

- **Flutter: Get Dependencies** - Run `fvm flutter pub get`
- **Flutter: Clean** - Clean build artifacts
- **Flutter: Analyze** - Run static analysis
- **Flutter: Format** - Format all Dart files
- **Test: Run All Tests** - Run all tests via script
- **Test: Run Unit Tests** - Run unit tests via script
- **Test: Run Widget Tests** - Run widget tests via script
- **Test: Run Integration Tests** - Run integration tests via script
- **Test: Generate Coverage Report** - Generate HTML coverage report

## Settings

The workspace settings configure:

- FVM Flutter SDK path (`.fvm/flutter_sdk`)
- Format on save
- File exclusions
- Search exclusions

## Extensions

Recommended extensions are listed in `extensions.json`. Install them when prompted or manually:

- Dart
- Flutter
- JSON Language Features

## Usage Tips

1. **Quick Debug**: Press `F5` to start debugging with the last used configuration
2. **Select Configuration**: Click the dropdown next to the play button to select a specific configuration
3. **Run Tests**: Use the test configurations or the test runner in the sidebar
4. **Tasks**: Use `Cmd+Shift+B` (Mac) or `Ctrl+Shift+B` (Windows/Linux) to run the default build task

