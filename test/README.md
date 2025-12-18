# Testing Guide

This directory contains all tests for the LingoDesk application.

## Test Structure

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
```

## Running Tests

### Run All Tests
```bash
fvm flutter test
```

### Run Unit Tests Only
```bash
fvm flutter test test/unit
```

### Run Widget Tests Only
```bash
fvm flutter test test/widget
```

### Run Specific Test File
```bash
fvm flutter test test/unit/core/bootstrap_test.dart
```

### Run Tests with Coverage
```bash
fvm flutter test --coverage
```

### Generate Coverage Report
```bash
# Run tests with coverage
fvm flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Types

### Unit Tests
Test individual functions, classes, and use cases in isolation.

**Location**: `test/unit/`

**Example**:
```dart
test('should return correct value', () {
  final result = calculateSomething(5);
  expect(result, equals(10));
});
```

### Widget Tests
Test individual widgets and their interactions.

**Location**: `test/widget/`

**Example**:
```dart
testWidgets('displays correct text', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Hello'), findsOneWidget);
});
```

### Integration Tests
Test complete user flows and app behavior.

**Location**: `integration_test/`

**Example**:
```dart
testWidgets('user can create an app', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  // Test user interactions
});
```

## Test Helpers

### TestHelpers
Located in `test/helpers/test_helpers.dart`, provides:
- `setUp()` - Initialize test environment
- `tearDown()` - Clean up after tests
- `createTestWidget()` - Create widgets with Material context

### Mock Factories
Located in `test/helpers/mock_factories.dart`, provides:
- Factory functions for creating test data
- Consistent test data across tests

### BLoC Test Helpers
Located in `test/helpers/bloc_test_helpers.dart`, provides:
- Utilities for testing BLoCs
- Common BLoC test patterns

## Best Practices

1. **Test Isolation**: Each test should be independent
2. **Arrange-Act-Assert**: Structure tests clearly
3. **Descriptive Names**: Use clear test names
4. **Mock External Dependencies**: Use mocks for repositories, APIs, etc.
5. **Test Edge Cases**: Include error cases and edge conditions
6. **Keep Tests Fast**: Unit tests should run quickly
7. **Maintain Test Coverage**: Aim for >80% coverage

## Coverage Goals

- **Unit Tests**: >90% coverage for business logic
- **Widget Tests**: >80% coverage for UI components
- **Integration Tests**: Cover critical user flows

## Running Integration Tests

Integration tests require a device or emulator:

```bash
# Run on connected device
fvm flutter test integration_test/app_test.dart

# Run on specific device
fvm flutter test integration_test/app_test.dart -d <device-id>
```

