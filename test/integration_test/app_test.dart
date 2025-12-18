import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lingo_desk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LingoDesk Integration Tests', () {
    testWidgets('App launches and displays welcome screen',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app launched successfully
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify welcome screen is displayed
      expect(find.text('Welcome to LingoDesk'), findsOneWidget);
      expect(find.text('Localization Management Tool'), findsOneWidget);
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

