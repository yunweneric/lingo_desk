import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_desk/core/app.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('LingoDeskApp Widget Tests', () {
    setUp(() async {
      await TestHelpers.setUp();
    });

    tearDown(() async {
      await TestHelpers.tearDown();
    });

    testWidgets('App renders with correct title', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      // Verify that the app title is displayed in the AppBar
      expect(find.text('LingoDesk'), findsOneWidget);
    });

    testWidgets('Placeholder home page displays welcome message', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      // Verify that the welcome text is displayed
      expect(find.text('Welcome to LingoDesk'), findsOneWidget);
      expect(find.text('Localization Management Tool'), findsOneWidget);

      // Verify that the translate icon is displayed
      expect(find.byIcon(Icons.translate), findsOneWidget);
    });

    testWidgets('App uses Material 3 theme', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      // Verify MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);

      // Get the MaterialApp widget to verify theme
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('App does not show debug banner', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const LingoDeskApp());

      // Get the MaterialApp widget to verify debug banner is disabled
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });
  });
}
