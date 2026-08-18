import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingo_desk/core/di/injection_container.dart' as di;
import 'package:lingo_desk/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LingoDesk Integration Tests', () {
    setUp(() async {
      // Start every test from a clean container and empty storage.
      SharedPreferences.setMockInitialValues({});
      await di.reset();
    });

    testWidgets('App launches and displays onboarding', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app launched successfully
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify the first onboarding step is displayed
      expect(
        find.text('Translate every locale from one clean desk'),
        findsOneWidget,
      );
    });

    // Add more integration tests as features are implemented
    // Example:
    // testWidgets('User can create a new app', (WidgetTester tester) async {
    //   app.main();
    //   await tester.pumpAndSettle();
    //
    //   // Find and tap the create button
    //   await tester.tap(find.byKey(const Key('create_app_button')));
    //   await tester.pumpAndSettle();
    //
    //   // Verify navigation to create screen
    //   expect(find.text('Create App'), findsOneWidget);
    // });
  });
}
