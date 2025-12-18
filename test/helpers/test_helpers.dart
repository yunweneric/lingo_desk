import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/di/injection_container.dart';

/// Test helper utilities for setting up and tearing down tests
class TestHelpers {
  /// Sets up the test environment
  ///
  /// Call this in setUp() to initialize test dependencies
  static Future<void> setUp() async {
    // Reset GetIt before each test
    await reset();

    // Register test-specific dependencies here
    // Example:
    // getIt.registerLazySingleton<Repository>(
    //   () => MockRepository(),
    // );
  }

  /// Tears down the test environment
  ///
  /// Call this in tearDown() to clean up after tests
  static Future<void> tearDown() async {
    await reset();
  }

  /// Creates a test widget with MaterialApp wrapper
  ///
  /// Useful for widget tests that need Material context
  static Widget createTestWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  /// Pumps widget and waits for animations to complete
  static Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
    Duration duration = const Duration(seconds: 1),
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(duration);
  }
}

/// Extension methods for WidgetTester
extension WidgetTesterExtensions on WidgetTester {
  /// Finds a widget by key and verifies it exists
  Finder findByKey(Key key) {
    return find.byKey(key);
  }

  /// Finds a widget by type and verifies it exists
  Finder findByType<T extends Widget>() {
    return find.byType(T);
  }

  /// Finds text and verifies it exists
  Finder findByText(String text) {
    return find.text(text);
  }
}
