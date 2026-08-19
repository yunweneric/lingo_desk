import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/di/injection_container.dart';
import 'package:lingo_desk/core/localization/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test helper utilities for setting up and tearing down tests
class TestHelpers {
  /// Sets up the test environment
  ///
  /// Call this in setUp() to initialize test dependencies
  static Future<void> setUp() async {
    // Reset GetIt before each test
    await reset();

    // The asset bundle caches the *future* of a load, not its result, so
    // a translation file first read in an earlier test hands this one a
    // future belonging to a dead test zone — and it never completes.
    rootBundle.clear();

    // Use in-memory storage and register the real dependency graph
    SharedPreferences.setMockInitialValues({});
    await init();

    // Translations, so widgets under test resolve keys rather than
    // throwing for want of a localization scope.
    await AppLocalization.ensureInitialized();

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
    return localized(MaterialApp(home: Scaffold(body: child)));
  }

  /// Wraps [child] in the localization scope the app is run inside, so a
  /// pumped widget can resolve translation keys.
  static Widget localized(Widget child) {
    return AppLocalization.wrap(
      startLocale: AppLocalization.fallbackLocale,
      child: child,
    );
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
